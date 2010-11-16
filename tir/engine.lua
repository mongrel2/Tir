-- Tir is a Lua micro web framework that implements nearly everything
-- most web frameworks have, but uses Mongrel2 to handle the dirty 
-- part of HTTP.  Read more about it at http://tir.mongrel2.org/
--
-- Tir is BSD licensed the same as Mongrel2.
--


require 'tir/strict'
require 'mongrel2'
require 'uuid'
require 'json'
require 'luasql.sqlite3'

module('Tir', package.seeall)


local STATE = setmetatable({}, {__mode="k"})
local CONFIG_FILE="conf/config.lua"
local TEMPLATES = "views/"
local UUID_TYPE = 'random'


-- Creates Web objects that the engine passes to your coroutines.
function web(conn, main, req, stateless)
    local controller

    if stateless then
        controller = main
    else
        controller = coroutine.create(main)
    end

    local Web = { 
        conn = conn, req = req,
        main=main, controller = controller,
        stateless = stateless
    }

    if req.headers.METHOD == 'JSON' then
        Web.session_id = req.data.session_id
    else
        Web.session_id = parse_session_id(req.headers['cookie'])
    end

    function Web:path()
        return self.req.headers.PATH
    end

    function Web:zap_session()
        -- to zap the session we just set a new random cookie instead
        self:set_cookie(make_session_cookie())
    end

    function Web:set_cookie(cookie)
        self.req.headers['set-cookie'] = cookie
    end

    function Web:get_cookie()
        return self.req.headers['cookie']
    end

    function Web:session()
        return self.session_id
    end

    function Web:send(data)
        return self.conn:reply_json(self.req, data)
    end

    function Web:close()
        self.conn:close(self.req)
    end

    function Web:redirect(url)
        self:page("", 303, "See Other", {Location=url})
    end

    function Web:error(data, code, status, headers)
        self:page(data, code, status, headers)
        self:close()
    end

    function Web:page(data, code, status, headers)
        headers = headers or {}

        if self.req.headers['set-cookie'] then
            headers['set-cookie'] = self.req.headers['set-cookie']
        end

        return self.conn:reply_http(self.req, data, code, status, headers)
    end

    if stateless then
        function Web:recv() error("This is a stateless handler, can't call recv.") end
        function Web:click() error("This is a stateless handler, can't call click.") end
        function Web:expect() error("This is a stateless handler, can't call expect.") end
        function Web:prompt() error("This is a stateless handler, can't call prompt.") end
        function Web:input() error("This is a stateless handler, can't call input.") end
    else
        function Web:recv()
            self.req = coroutine.yield()
            return self.req
        end

        function Web:click(requires)
            local req = self:recv()
            return req.headers.PATH
        end

        function Web:expect(pattern, data, code, status, headers)
            self:page(data, code, status, headers)
            local path = self:click()

            if string.match(path, pattern) then
                return path, nil
            else
                self:error("Not found", 404, "Not Found")
                return nil, "Not Found"
            end
        end


        function Web:prompt(data, code, status, headers)
            self:page(data, code, status, headers)
            return self:input()
        end

        function Web:input()
            local req = self:recv()
            return parse_form(req)
        end
    end

    return Web
end

-- Creates Form objects for validating form input in the coroutines.
function form(required_fields)
    local Form = {
        required_fields = required_fields
    }

    function Form:requires(params)
        local errors = {}
        local had_errors = false

        for _, field in ipairs(self.required_fields) do
            if not params[field] or #params[field] == 0 then
                errors[field] = 'This is required.'
                had_errors = true
            end
        end

        if had_errors then
            params.errors = json.encode(errors)
            return false
        else
            params.errors = nil
            return true
        end
    end

    function Form:clear(params)
        params.errors = nil
    end

    function Form:valid(params)
        local has_required = self:requires(params)

        if has_required and self.required_fields.validator then
            return self.required_fields.validator(params)
        else
            return has_required
        end
    end

    function Form:parse(req)
        return parse_form(req)
    end

    return Form
end


-- Used in template parsing to figure out what each {} does.
local VIEW_ACTIONS = {
    ['{%'] = function(code)
        return code
    end,

    ['{{'] = function(code)
        return ('_result[#_result+1] = %s'):format(code)
    end,

    ['{('] = function(code)
        return ([[ 
            if not _children[%s] then
                _children[%s] = Tir.view(%s)
            end

            _result[#_result+1] = _children[%s](getfenv())
        ]]):format(code, code, code, code)
    end,

    ['{<'] = function(code)
        return ('_result[#_result+1] =  Tir.escape(%s)'):format(code)
    end,
}


-- Takes a view template and optional name (usually a file) and 
-- returns a function you can call with a table to render the view.
function compile_view(tmpl, name)
    local tmpl = tmpl .. '{}'
    local code = {'local _result, _children = {}, {}\n'}

    for text, block in string.gmatch(tmpl, "([^{]-)(%b{})") do
        local act = VIEW_ACTIONS[block:sub(1,2)]
        local output = text

        if act then
            code[#code+1] =  '_result[#_result+1] = [[' .. text .. ']]'
            code[#code+1] = act(block:sub(3,-3))
        elseif #block > 2 then
            code[#code+1] = '_result[#_result+1] = [[' .. text .. block .. ']]'
        else
            code[#code+1] =  '_result[#_result+1] = [[' .. text .. ']]'
        end
    end

    code[#code+1] = 'return table.concat(_result)'

    code = table.concat(code, '\n')
    local func, err = loadstring(code, name)

    if err then
        assert(func, err)
    end

    return function(context)
        assert(context, "You must always pass in a table for context.")
        setmetatable(context, {__index=_G})
        setfenv(func, context)
        return func()
    end
end


-- Crafts a new view from the given file in the TEMPLATES directory.
-- If the ENV[PROD] is set to something then it will do this once.
-- Otherwise it returns a function that reloads the template since you're
-- in developer mode.
function view(name)
    if os.getenv('PROD') then
        return compile_view(load_file(TEMPLATES, name), name)
    else
        return function (params)
            return compile_view(load_file(TEMPLATES, name), name)(params)
        end
    end
end


function make_session_id()
    return 'APP-' .. uuid.new(UUID_TYPE)
end

function make_session_cookie(ident)
    return 'session="' .. (ident or make_session_id()) .. '"; Version="1"; Path="/"'
end

function parse_session_id(cookie)
    if not cookie then return nil end

    return cookie:match('session="(APP-[a-z0-9\-]+)";?')
end


local function json_ident(req)
    local ident = req.data.session_id

    if not ident then
        ident = make_session_id()
        req.data.session_id = ident
    end

    return ident
end


local function http_cookie_ident(req)
    local ident = parse_session_id(req.headers['cookie'])

    if not ident then
        ident = make_session_id()
        cookie = make_session_cookie(ident)

        req.headers['set-cookie'] = cookie
        req.headers['cookie'] = cookie
    end

    return ident
end

-- This is the default way an engine identifies a connection, using
-- cookies.  You can change this to use just the connection id too.
-- It will handle either JSON requests or HTTP requests and it will
-- craft cookies for you.
local function default_ident(req)
    if req.headers.METHOD == "JSON" then
        return json_ident(req)
    else
        return http_cookie_ident(req)
    end
end


-- Simplistic HTML escaping.
function escape(s)
    if s == nil then return '' end

    local esc, i = s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
    return esc
end

-- Simplistic URL decoding that can handle + space encoding too.
function url_decode(data)
    return data:gsub("%+", ' '):gsub('%%([0-9A-F][0-9A-F])', function (s)
        return string.char(tonumber(s, 16))
    end)
end

-- Basic URL parsing that handles simple key=value&key=value setups
-- and decodes both key and value.
function url_parse(data)
    local result = {}
    data = data .. '&'
    for k,v in data:gmatch("(.-)=(.-)&") do
        result[url_decode(k)] = url_decode(v)
    end

    return result
end


-- Parses a form out of the request, figuring out if it's something that
-- we can handle.  It might not handle all the really weird ways forms are
-- encoded, so YYMV.
function parse_form(req)
    local headers = req.headers
    local params = {}

    if headers.METHOD == 'GET' then
        if headers.QUERY then
            params = url_parse(headers.QUERY)
        end
    elseif headers.METHOD == 'POST' then
        if headers['content-type'] == 'application/x-www-form-urlencoded' then
            params = url_parse(req.body)
        end
    end

    params.__session = parse_session_id(req.headers['cookie'])

    return params
end


-- Used for dumping json so it can be displayed to someone.
local function pretty_json(tab)
    return json.encode(tab):gsub('","', '",\n"')
end


-- Loads a source file, but converts it with line numbering only showing
-- from firstline to lastline.
local function load_lines(source, firstline, lastline)
    local f = io.open(source)
    local lines = {}
    local i = 0

    -- TODO: this seems kind of dumb, probably a better way to do this
    for line in f:lines() do
        i = i + 1

        if i >= firstline and i <= lastline then
            lines[#lines+1] = ("%0.4d: %s"):format(i, line)
        end
    end

    return table.concat(lines,'\n')
end


-- Reports errors back to the browser so the user has something to work with.
local function report_error(conn, request, error, state)
    local pretty_req = pretty_json(request)
    local trace = debug.traceback(state.controller, error)
    local info
    local source = nil

    if state.stateless then
        info = debug.getinfo(state.main)
    else
        info = debug.getinfo(state.controller, state.main)
    end

    if info.source:match("@.+$") then
        source = load_lines(info.short_src, info.linedefined, info.lastlinedefined)
    else
        source = info.source
    end

    local page = ERROR_PAGE {error=trace, source=source, request=pretty_req}
    conn:reply_http(request, page, 500, "Internal Server Error")
    print("ERROR", error)
end


local function exec_state(first_run, state, request, before, after)
    local good, error 

    if before then
        good, error = pcall(before, state, request)
        if not good then return good, error end
        if not error then return false end
    end
   
    if first_run then
        good, error = coroutine.resume(state.controller, state, request)
    else
        good, error = coroutine.resume(state.controller, request)
    end

    if after then
        local after_good, after_error = pcall(after, state, request)
        if not after_good then return after_good, after_error end
        if not after_error then return false end
    end

    return good, error
end


local function run_coro(main, conn, request, conn_id, before, after)
    -- The client has sent data
    local state = STATE[conn_id]
    local good, error

    -- If the client hasn't sent data before, create a new main.
    if not state then
        state = web(conn, main, request, false)
        STATE[conn_id] = state
        good, error = exec_state(true, state, request, before, after)
    else
        state.req = request
        good, error = exec_state(false, state, request, before, after)
    end

    if not good and error then
        report_error(conn, request, error, state)
    end

    -- If the main is done or we got an eror, stop tracking the client
    if not good or coroutine.status(state.controller) == "dead" then
        STATE[conn_id] = nil
    end

    return good, error
end


local function run_stateless(conn, main, request)
    local state = web(conn, main, request, true)
    local good, error = pcall(main, state, request)

    if not good and error then
        report_error(conn, request, error, state)
    end
end

-- Runs a Tir engine using the given connection and configuration.
function run(conn, config)
    local main, ident, disconnect = config.main, config.ident, config.disconnect
    local before, after = config.before, config.after
    local good, error
    local request, msg_type, controller
    local conn_id
    local stateless = config.stateless or false
    local state

    while true do
        -- Get a message from the Mongrel2 server
        good, request = pcall(conn.recv_json, conn)

        if good then
            msg_type = request.data.type

            if msg_type == 'disconnect' then
                -- The client has disconnected
                if disconnect then disconnect(request) end
                print("DISCONNECT", request.conn_id)
            else
                print("REQUEST " .. config.route .. ":" .. request.conn_id, os.date(), request.headers.PATH, request.headers.METHOD)

                -- always do this
                conn_id = ident(request)

                if stateless then
                    run_stateless(conn, main, request)
                else
                    run_coro(main, conn, request, conn_id, before, after)
                end
            end
        else
            print("FATAL ERROR", good, request)
        end
    end
end

-- Loads the Handler config out of the Mongrel2 sqlite config so we don't
-- have to specify it over and over.
local function load_mongrel2_config(config)
    local env = assert(luasql.sqlite3())
    local conn = assert(env:connect(config.config_db))
    local cur = assert(conn:execute("select send_spec, recv_spec from handler where id=(select target_id from route where target_type='handler' and path='" .. config.route .. "')"))
    local row = cur:fetch({}, "a")

    assert(row, "Did not find anything for route " .. config.route)
    config.sub_addr = row.send_spec
    config.pub_addr = row.recv_spec

    cur:close()
    conn:close()
    env:close()
end



-- Starts a Tir engine, wiring up all the stuff we need for this process
-- using the given config.  The config is expected to have at least
-- {route='/path', main=handler_func}.  In addition to that you can put
-- other settings that are common to all handlers in CONFIG_FILE (conf/config.lua).
-- Options you can override are: templates, ident, sender_id, sub_addr, pub_addr, io_threads
function start(config)
    setfenv(assert(loadfile(CONFIG_FILE)), config)()
    TEMPLATES = config.templates or TEMPLATES
    config.ident = config.ident or default_ident

    load_mongrel2_config(config)

    -- Connect to the Mongrel2 server
    print("CONNECTING", config.route, config.sender_id, config.sub_addr, config.pub_addr)

    local ctx = mongrel2.new(config.io_threads)
    local conn = ctx:new_connection(config.sender_id, config.sub_addr, config.pub_addr)

    assert(conn, "Failed to start Mongrel2 connection.")

    -- Run the engine
    run(conn, config)
end



-- Helper function that does a debug dump of the given data.
function dump(data)
    json.util.printValue({['*'] = data}, '*')
end

-- Helper function that loads a file into ram.
function load_file(from_dir, name)
    local intmp = assert(io.open(from_dir .. name, 'r'))
    local content = intmp:read('*a')
    intmp:close()

    return content
end


-- The basic error page HTML.  Nothing fancy, but you can change it if you want.
ERROR_PAGE = compile_view [[
<html><head><title>Tir Error</title></head> 
<body>
<p>There was an error processing your request.</p>
<h1>Stack Trace</h1>
<pre>
{{ error }}
</pre>
<h1>Source Code</h1>
<pre>
{{ source }}
</pre>
<h1>Request</h1>
<pre>
{{ request }}
</pre>
</body>
</html>
]]


