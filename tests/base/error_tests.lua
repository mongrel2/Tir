require 'tir/engine'


function fake_main()
    print("TEST")
end

context("Tir", function()
    context("error", function()
        test("report_error", function()
            local state = {main = fake_main, stateless=true}
            local reply_called = false

            local fake_conn = {reply_http = function (...) reply_called = true end}
            Tir.report_error(fake_conn, {}, "test error", state)
    
            assert_true(reply_called)
        end)
    end)
end)

