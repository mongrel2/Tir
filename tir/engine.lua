-- Tir is a Lua micro web framework that implements nearly everything
-- most web frameworks have, but uses Mongrel2 to handle the dirty 
-- part of HTTP.  Read more about it at http://tir.mongrel2.org/
--
-- Tir is BSD licensed the same as Mongrel2.
--

require 'tir.strict'

module('Tir', package.seeall)

require 'tir.util'
require 'tir.view'
require 'tir.form'
require 'tir.session'
require 'tir.error'
require 'tir.web'
require 'tir.m2'
require 'tir.task'

local STATE = setmetatable({}, {__mode="k"})
local CONFIG_FILE="conf/config.lua"
DEFAULT_ALLOWED_METHODS = {GET = true, POST = true, PUT = true, JSON = true, XML = true}

local function exec_state(state, request, before, after, action_func)
    local good, err

    if before then
        good, err = pcall(before, state, request)
        if not good then return good, err end
        if not err then return false end
    end

    good, err = action_func(state, request)
   
    if after then
        local after_good, after_err = pcall(after, state, request)
        if not after_good then return after_good, after_err end
        if not after_err then return false end
    end

    return good, err
end


local function run_coro(main, conn, request, conn_id, before, after)
    -- The client has sent data
    local state = STATE[conn_id]
    local good, err

    -- If the client hasn't sent data before, create a new main.
    if not state then
        state = web(conn, main, request, false)
        STATE[conn_id] = state
        good, err = exec_state(state, request, before, after,
            function (s, r)
                return coroutine.resume(state.controller, state, request) 
            end)
    else
        state.req = request

        good, err = exec_state(state, request, before, after,
            function (s, r)
                return coroutine.resume(s.controller, r) 
            end)
    end

    if not good and err then
        report_error(conn, request, err, state)
    end

    -- If the main is done or we got an eror, stop tracking the client
    if not good or coroutine.status(state.controller) == "dead" then
        STATE[conn_id] = nil
    end
end


local function run_stateless(conn, main, request, before, after)
    local state = web(conn, main, request, true)

    local good, err = exec_state(state, request, before, after, function(s,r)
        return pcall(s.controller, s, r)
    end)

    if not good and err then
        report_error(conn, request, err, state)
    end
end


-- Runs a Tir engine using the given connection and configuration.
function run(conn, config)
    local main, ident, disconnect = config.main, config.ident, config.disconnect
    local before, after = config.before, config.after
    local good, err
    local request, msg_type, controller
    local conn_id
    local stateless = config.stateless or false

    while true do
        -- Get a message from the Mongrel2 server
        request, err = conn:recv()

        if request and not err then
            if not config.methods[request.headers.METHOD] then
                basic_error(conn, request, "Method Not Allowed",
                    405, "Method Not Allowed", {Allow = config.allowed_methods_header}
                )
            else
                msg_type = request.data.type

                if msg_type == 'disconnect' then
                    -- The client has disconnected
                    if disconnect then disconnect(request) end
                    print("DISCONNECT", request.conn_id)
                else
                    -- always do this so the request is setup also
                    conn_id = ident(request)

                    print("REQUEST " .. config.route .. ":" .. request.conn_id, os.date(), request.headers.PATH, request.headers.METHOD, request.session_id)

                    if stateless then
                        run_stateless(conn, main, request, before, after)
                    else
                        run_coro(main, conn, request, conn_id, before, after)
                    end
                end
            end
        else
            print("FATAL ERROR", good, request, err)
        end
    end
end

function update_config(config, config_file)
    local originals = Tir.clone(config)
    setfenv(assert(loadfile(config_file)), config)()
    Tir.update(config, originals)

    return config
end


-- Starts a Tir engine, wiring up all the stuff we need for this process
-- using the given config.  The config is expected to have at least
-- {route='/path', main=handler_func}.  In addition to that you can put
-- other settings that are common to all handlers in CONFIG_FILE (conf/config.lua).
-- Options you can override are: templates, ident, sender_id, sub_addr, pub_addr, io_threads
function start(config)
    config = update_config(config, config.config_file or CONFIG_FILE)
    TEMPLATES = config.templates or TEMPLATES
    config.ident = config.ident or default_ident

    -- we want to config fast default methods so we can abort any that aren't
    -- in the whitelist
    config.methods = config.methods or DEFAULT_ALLOWED_METHODS
    allowed = {}

    for m, yes in pairs(config.methods) do
        if yes then allowed[#allowed + 1] = m end
    end

    config.allowed_methods_header = table.concat(allowed, ' ')

    Tir.M2.load_config(config)
    local conn = assert(Tir.M2.connect(config), "Failed to connect to Mongrel2.")

    -- Run the engine
    run(conn, config)
end


-- Convenient way to start a stateless style handler, pretty much
-- just sets the config.stateless = true variable for you.
function stateless(config)
    config.stateless = true
    Tir.start(config)
end


-- Starts an evented style handler, which really just makes a little
-- wrapper closure that does a simple pattern match on your handler
-- and then calls the function that matches it route.
function evented(handler, pattern)
    assert(not handler.config.main, "main is a reserved function name for evented.")
    
    local config = handler.config
    handler.config = nil
    local pattern = pattern or config.route .. '/' .. '([%w_%-]+)/?(.*)'

    if config.stateless == nil then config.stateless = true end

    config.main = function (web, req)
        local action, extra = web:path():match(pattern)
        local action_func = handler[action or 'index']

        if action_func then
            local params

            if handler.form then
                params = handler.form:parse(req)
            else 
                params = Tir.parse_form(req)
            end

            action_func(web, req, params)
        else
            print(("Action %s not found for handler %s."):format(action or 'index', config.route))
            web:not_found()
        end
    end

    Tir.start(config)
end

-- Mostly used in testing to inspect on running states.
function get_state(ident)
    return STATE[ident]
end


