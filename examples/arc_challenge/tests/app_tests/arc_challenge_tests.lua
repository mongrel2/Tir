require 'tir/testing'
require 'app/arc_challenge'

context("Arc Challenge", function()
    context("interaction", function()
        test("do it", function()
            local tester = Tir.Tests.browser("tester")

            -- click assumes you want a 200 all the time and just returns
            -- the response it got
            local resp = tester:click("/Arc")
            assert_match(".*Tir Arc Challenge.*<form.*", resp.body) 

            -- you can also pass what you expect in as another parameter
            -- with values that are converted to strings and then pattern matched
            resp = tester:submit("/Arc", {msg = "Hello!"}, {body = ".*click here.*"})

            resp = tester:click("/Arc", {code = 200, body = ".*You said Hello!.*"})

            tester:click("/Arc")

            -- we can also make sure that this handler exited, or
            -- in this case didn't since it's a permanent loop
            assert_false(tester:exited())
        end)
    end)
end)


