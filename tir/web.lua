module('Tir', package.seeall)

local TIR_VERSION='Tir/0.8-a9b52939a3'
local DEFAULT_CTYPE='text/html'

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

    function Web:path()
        return self.req.headers.PATH
    end

    function Web:method()
        return self.req.headers.METHOD
    end

    function Web:request_is_json()
        return self.req.headers['x-requested-with'] == "XMLHttpRequest"
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
        return self.req.session_id
    end

    function Web:send(data)
        return self.conn:reply_json(self.req, data)
    end

    function Web:close()
        self.conn:close(self.req)
    end

    function Web:json(data, ctype)
        self:page(json.encode(data), 200, "OK", {['content-type'] = ctype or 'application/json'})
    end

    function Web:redirect(url)
        self:page("", 303, "See Other", {Location=url, ['content-type'] = false})
    end

    -- reports an error then closes the connection
    function Web:error(data, code, status, headers)
        self:page(data, code, status, headers or {['content-type'] = false})
        self:close()
    end

    -- a bunch of common errors and responses
    function Web:not_found(msg) self:error(msg or 'Not Found', 404, 'Not Found') end
    function Web:unauthorized(msg) self:error(msg or 'Unauthorized', 401, 'Unauthorized') end
    function Web:forbidden(msg) self:error(msg or 'Forbidden', 403, 'Forbidden') end
    function Web:bad_request(msg) self:error(msg or 'Bad Request', 400, 'Bad Request') end

    -- Used to send typical web page responses.  If you don't include a content-type then it
    -- will use DEFAULT_CTYPE.  However, if you set the content-type to false it will remove
    -- it and not use one.
    function Web:page(data, code, status, headers)
        headers = headers or {}

        if self.req.headers['set-cookie'] then
            headers['set-cookie'] = self.req.headers['set-cookie']
        end

        headers['server'] = TIR_VERSION
        local ctype = headers['content-type']

        if ctype == nil then
            headers['content-type'] = DEFAULT_CTYPE
        elseif ctype == false then
            headers['content-type'] = nil
        end

        return self.conn:reply_http(self.req, data, code, status, headers)
    end

    -- shortcut for a common Xhr response
    function Web:ok(msg) self:page(msg or 'OK', 200, 'OK') end

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

