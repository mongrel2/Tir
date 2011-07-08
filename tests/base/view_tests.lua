require 'tir.engine'

local TEST_TEMPLATE = [[This is a {{ test }}.]]
local ALL_ACTIONS = [[{% if test == 1 then %}{{ hello }}{% elseif test == 2 then %}{< hello >}{% else %}{( "tir-scm-0.rockspec" )}{% end %}]]

local ALL_ACTION_BIG_RESULT = nil

context("Tir", function()
    context("view", function()
        test("compile_view", function()
            local tmpl = Tir.compile_view(TEST_TEMPLATE, "error")
            assert_not_nil(tmpl)
            
            assert_equal(tmpl {test='big'}, "This is a big.")
        end)

        test("view", function()
            local tmpl = Tir.view("tir-scm-0.rockspec")
            assert_not_nil(tmpl)
            -- we use this in the next test
            ALL_ACTION_BIG_RESULT = tmpl {VERSION=10, MD5=""}
        end)

        test("actions", function()
            local tmpl = Tir.compile_view(ALL_ACTIONS, "actions")
            assert_not_nil(tmpl)
            assert_equal(tmpl {test=1, hello='test 1'}, "test 1")
            assert_equal(tmpl {test=2, hello='<test 2>'}, "&lt;test 2&gt;")
            assert_equal(tmpl {test=3, VERSION=10, MD5=""}, ALL_ACTION_BIG_RESULT)
        end)
    end)
end)

