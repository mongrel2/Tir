
require 'tir/engine'


context("Tir", function()
    context("session", function()
        test("make_session_id", function()
            local id1 = Tir.make_session_id()
            assert_not_nil(id1)

            local id2 = Tir.make_session_id()
            assert_not_nil(id2)

            assert_not_equal(id1, id2)
        end)

        test("make_expires", function()
            local expire = Tir.make_expires()
            assert_not_nil(expire)
            assert_match('^[A-Z][%w]-, %d%d%-[A-Z][%w]-%-%d%d%d%d %d%d:%d%d:%d%d GMT$', expire)
        end)

        test("make_session_cookie", function()
            local cookie = Tir.make_session_cookie(Tir.make_session_id())
            assert_not_nil(cookie)

            assert_match("^session=.-; version=1; path=/; expires=.+$", cookie)
        end)

        test("json_ident", function()
            local req = {data = {}}

            local ident = Tir.json_ident(req)
            assert_not_nil(ident)
            assert_not_nil(req.data.session_id)
            assert_equal(req.data.session_id, ident)
            assert_equal(Tir.json_ident(req), ident)
        end)

        test("http_cookie_ident", function()
            local req = { headers = {
                cookie = Tir.make_session_cookie(Tir.make_session_id())
            }}

            local ident = Tir.http_cookie_ident(req)

            assert_not_nil(ident)
            assert_not_nil(req.headers['cookie'])
            assert_equal(Tir.http_cookie_ident(req), ident)
        end)

        test("default_ident", function()
            do
                local req = {data = {}, headers = { METHOD = 'JSON'}}

                local ident = Tir.default_ident(req)
                assert_not_nil(ident)
                assert_not_nil(req.data.session_id)
                assert_equal(req.data.session_id, ident)
            end


            do
                local req = { headers = {
                    cookie = Tir.make_session_cookie(Tir.make_session_id())
                }}

                local ident = Tir.default_ident(req)

                assert_not_nil(ident)
                assert_not_nil(req.headers['cookie'])
            end
        end)
    end)
end)

