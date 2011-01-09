require 'tir/engine'

module('Tir.Tests', package.seeall)

local CONFIG_FILE = "conf/testing.lua"
local TEMPLATES = "views/"

-- These globals are used to implement fake state for requests.
local SENDER_ID = "3ddfbc58-a249-45c9-9446-00b73de18f7c"

local CONN_ID = 1

local RUNNERS = {}

local RESPONSES = {}

local DEFAULT_UAGENT = "curl/7.19.7 (i486-pc-linux-gnu) libcurl/7.19.7 OpenSSL/0.9.8k zlib/1.2.3.3 libidn/1.15" 

-- This constructs a fake mongrel2 connection that allows for running
-- a handler but yields to receive a request and stuffs all the responses
-- into RESPONSES for later inspection.
local function FakeConnect(config)
    local conn = {config = config}

    function conn:recv()
        local req = coroutine.yield()
        assert(req.headers.PATH:match(self.config.route), ("Invalid request %q sent to handler: %q"):format(req.headers.PATH, self.config.route))
        return req
    end

    function conn:send(uuid, conn_id, msg)
        RESPONSES[#RESPONSES + 1] = {
            type = "send",
            conn_id = conn_id,
            msg = msg
        }
    end

    function conn:reply(req, msg)
        RESPONSES[#RESPONSES + 1] = {
            type = "reply",
            req = req,
            msg = msg
        }
    end

    function conn:reply_json(req, data)
        RESPONSES[#RESPONSES + 1] = {
            type = "reply_json",
            req = req,
            data = data
        }
    end

    function conn:reply_http(req, body, code, status, headers)
        RESPONSES[#RESPONSES + 1] = {
            type = "reply_http",
            req = req,
            body = body,
            code = code or 200,
            status = status or 'OK',
            headers = headers or {}
        }
    end

    function conn:deliver(uuid, idents, data)
        RESPONSES[#RESPONSES + 1] = {
            type = "deliver",
            idents = idents,
            data = data
        }
    end

    function conn:deliver_json(uuid, idents, data)
        RESPONSES[#RESPONSES + 1] = {
            type = "deliver_json",
            idents = idents,
            data = data
        }
    end

    function conn:deliver_http(uuid, idents, body, code, status, headers)
        RESPONSES[#RESPONSES + 1] = {
            type = "deliver_http",
            idents = idents,
            body = body,
            code = code or 200,
            status = status or 'OK',
            headers = headers
        }
    end

    function conn:deliver_close(uuid, idents)
        RESPONSES[#RESPONSES + 1] = {
            type = "deliver_close",
            idents = idents
        }
    end

    function conn:close()
        CONN_ID = CONN_ID + 1
    end

    return conn
end

-- Replaces the base start with one that creates a fake m2 connection.
Tir.start = function(config)
    config = Tir.update_config(config, 'conf/testing.lua')

    config.methods = config.methods or Tir.DEFAULT_ALLOWED_METHODS

    config.ident = config.ident or Tir.default_ident

    local conn = FakeConnect(config)

    local runner = coroutine.wrap(Tir.run)
    runner(conn, config)

    -- This runner is used later to feed fake requests to the Tir.run loop.
    RUNNERS[config.route] = runner
end

-- Makes fake requests with all the right stuff in them.
function fake_request(session, method, path, query, body, headers, data)
    local req = {
        conn_id = CONN_ID,
        sender = SENDER_ID,
        path = path,
        body = body or "",
        data = data or {},
    }

    if method == "JSON" then
        req.data.session_id = session.SESSION_ID
    end

    req.headers  = {
        PATTERN = path,
        METHOD = method,
        QUERY = query,
        VERSION = "HTTP/1.1",
        ['x-forwarded-for'] = '127.0.0.1',
        host = "localhost:6767",
        PATH = path,
        ['user-agent'] = DEFAULT_UAGENT,
        cookie = session.COOKIE,
        URI = query and (path .. '?' .. query) or path,
    }

    Tir.update(req.headers, headers or {})

    return req
end


function route_request(req)
    for pattern, runner in pairs(RUNNERS) do
        if req.headers.PATH:match(pattern) then
            return runner(req)
        end
    end

    assert(false, ("Request for %q path didn't match any loaded handlers."):format(req.headers.PATH))
end


-- Sets up a fake "browser" that is used in tests to pretend to send
-- and receive requests and then analyze the results.  It assumes a 
-- string request/response mode of operation and will throw errors if
-- that's not followed.
function browser(name, session_id, conn_id)
    CONN_ID = CONN_ID + 1

    local Browser = {
        RESPONSES = {},
        COOKIE = nil,
        SESSION_ID = nil,
        name = name,
    }

    function Browser:send(method, path, query, body, headers, data)
        route_request(fake_request(self, method, path, query, body, headers, data))

        local resp_count = #RESPONSES

        while #RESPONSES > 0 do
            local resp = table.remove(RESPONSES)
            if resp.req then
                self:extract_cookie(resp.req.headers)
            end
            self.RESPONSES[#self.RESPONSES] = resp
        end

        assert(resp_count > 0, ("Your application did not send a response to %q, that'll cause your browser to stall."):format(path))

        assert(resp_count == 1, ("A request for %q sent %d responses, that'll make the browser do really weird things."):format(path, resp_count))

    end

    function Browser:expect(needed)
        local last = self.RESPONSES[#self.RESPONSES]

        for k,v in pairs(last) do
            local pattern = needed[k]

            if pattern then
                if not tostring(v):match(tostring(pattern)) then
                    error(("[%s] Failed expect: %q did not match %q but was %q:%q"
                        ):format(self.name, k, pattern, v, last.body))
                end
            end
        end

        return last
    end


    function Browser:exited()
        return self.SESSION_ID and not Tir.get_state(self.SESSION_ID)
    end

    function Browser:extract_cookie(headers)
        local cookie = headers['set-cookie']

        if cookie and cookie ~= self.COOKIE then
            self.COOKIE = cookie
            self.SESSION_ID = Tir.parse_session_id(cookie)
        end
    end

    function Browser:click(path, expect)
        self:send("GET", path)
        return self:expect(expect or { code = 200 })
    end

    function Browser:submit(path, form, expect, headers)
        local body = Tir.form_encode(form)
        headers = headers or {}

        expect = expect or {code = 200}
        if not expect.code then expect.code = 200 end

        headers['content-type'] = "application/x-www-form-urlencoded"
        headers['content-length'] = #body

        self:send("POST", path, nil, body, headers)

        return self:expect(expect)
    end

    function Browser:xhr(path, form, expect)
        local headers = {['x-requested-with'] = "XMLHttpRequest"}
        self:submit(path, form, headers)
        return self:expect(expect or { code = 200 })
    end

    function Browser:query(path, params, expect)
        local query = Tir.form_encode(form)
        self:send("GET", path, query)
        return self:expect(expect or { code = 200 })
    end

    return Browser
end
