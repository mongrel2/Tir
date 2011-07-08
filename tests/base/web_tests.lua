require 'tir.engine'

local fake_conn = { 
    closed = false,
    reply_sent = nil,
    last_code = nil,

    reply_json = function(self, req, data)
        self.reply_sent = data 
    end,

    close = function(self, req) 
        self.closed = true 
    end,

    reply_http = function(self, req, data, code, status, headers)
        self.reply_sent = data
        self.last_code = code
    end,
}

local session_id = Tir.make_session_id()

local fake_req = {headers = {
    PATH = "/test", METHOD = "GET", cookie = Tir.make_session_cookie(session_id),
}, session_id = session_id}

function assert_sent(conn, expected)
    assert_equal(conn.reply_sent, expected)
    conn.reply_sent = nil
end

function assert_closed(conn)
    assert_true(conn.closed)
    conn.closed = false
end

function assert_status(conn, code)
    assert_equal(conn.last_code, code)
    conn.last_code = nil
end


function fake_response(coro_run)
    local c = coroutine.create(coro_run)
    coroutine.resume(c)
    coroutine.resume(c, fake_req)
end

context("Tir", function()
    context("web", function()
        test("path", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            assert_equal(web:path(), "/test")
        end)

        test("method", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            assert_equal(web:method(), "GET")
        end)

        test("session", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            assert_not_nil(web:session())
            assert_match('APP%-.*', web:session())
        end)

        test("get_cookie", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            local cookie = web:get_cookie()
            assert_not_nil(cookie)
        end)

        test("set_cookie", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:set_cookie("testing")
            assert_not_nil(fake_req.headers['set-cookie'])
            fake_req.headers['set-cookie'] = nil
        end)

        test("zap_session", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:zap_session()
            assert_not_nil(fake_req.headers['set-cookie'])
        end)


        test("send", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:send("HELLO")
            assert_sent(fake_conn, "HELLO")
        end)

        test("close", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:close()
            assert_closed(fake_conn)
        end)

        test("redirect", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:redirect("/url")
            assert_sent(fake_conn, "")
            assert_status(fake_conn, 303)
        end)

        test("error", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:not_found()
            assert_sent(fake_conn, 'Not Found')
            assert_status(fake_conn, 404)

            web:unauthorized()
            assert_sent(fake_conn, 'Unauthorized')
            assert_status(fake_conn, 401)

            web:forbidden('TEST')
            assert_sent(fake_conn, 'TEST')
            assert_status(fake_conn, 403)

            web:bad_request()
            assert_sent(fake_conn, 'Bad Request')
            assert_status(fake_conn, 400)
        end)

        test("page", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web:page("Howdy", 200)
            assert_sent(fake_conn, "Howdy")
            assert_status(fake_conn, 200)
            web:page("Howdy", 300)
            assert_status(fake_conn, 300)

            web:ok()
            assert_sent(fake_conn, "OK")
            assert_status(fake_conn, 200)
        end)

        test("stateless blocks yielded functions", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, true)
            local good, err = pcall(web.recv, web)
            assert_false(good)
            assert_match('This is a stateless handler.*', err)
        end)

        test("recv", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web.req = nil

            fake_response(function () web:recv() end)

            assert_not_nil(web.req)
        end)

        test("click", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            web.req = nil
            local path = nil

            fake_response(function () path = web:click() end)

            assert_equal(web:path(), "/test")
        end)

        test("expect", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            fake_response(function () 
                path = web:expect('/test', "Hello", 304) 
            end)

            assert_equal(web:path(), "/test")
            assert_sent(fake_conn, "Hello")
            assert_status(fake_conn, 304)
        end)

        test("prompt", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            fake_response(function () path = web:prompt("Hello") end)
            assert_sent(fake_conn, "Hello")
        end)

        test("input", function()
            local web = Tir.web(fake_conn, fake_main, fake_req, false)
            local params = nil

            fake_response(function() params = web:input() end)

            assert_not_nil(params)
            assert_equal(#params, 0)
        end)
    end)
end)

