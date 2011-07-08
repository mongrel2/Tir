require 'tir.engine'

local MULTIPART_BOUNDARY = "multipart/form-data; boundary=---------------------------21302070922692600111282794892"
local MULTIPART_BODY = Tir.load_file("tests/data/", "multipart_sample.txt")

context("Tir", function()
    context("view", function()
        test("Form validation", function()
            local valid_check = true
            local test_form = Tir.form {"name", "age", validator = function (params)
                return valid_check
            end}

            assert_true(test_form:valid {name="zed", age="100"})

            local params = {name="zed"} 
            assert_false(test_form:valid(params))
            assert_not_nil(params.errors)

            test_form:clear(params)
            assert_nil(params.errors)

            valid_check = false
            assert_false(test_form:valid {name="zed", age="100"})
        end)

        test("parse_headers GET request", function()
            local fake_req = {headers = {METHOD='GET', QUERY='name=zed&age=100'}}
            local test_form = Tir.form {"name", "age"}

            local params = test_form:parse(fake_req)
            assert_equal(params.name, "zed")
            assert_equal(params.age, "100")

            fake_req.headers.QUERY = nil

            local params = test_form:parse(fake_req)
            assert_equal(#params, 0)
        end)

        test("parse_headers POST form", function()
            local fake_req = {
                headers = {
                    METHOD = 'POST',
                    ["content-type"] = 'application/x-www-form-urlencoded'
                },
                body = 'name=zed&age=100'
            }

            local test_form = Tir.form {"name", "age"}

            local params = test_form:parse(fake_req)
            assert_equal(params.name, "zed")
            assert_equal(params.age, "100")

            fake_req.body = nil

            local params = test_form:parse(fake_req)
            assert_equal(#params, 0)
        end)

        test("parse_headers POST multipart", function()
            local fake_req = {
                headers = {
                    METHOD = 'POST',
                    ["content-type"] = MULTIPART_BOUNDARY
                },
                body = MULTIPART_BODY
            }

            local test_form = Tir.form {"name", "age"}

            local params = test_form:parse(fake_req)

            assert_equal(params.full_name, "Zed A. Shaw")
            assert_equal(params.email, "zed@zed.com")
            assert_equal(params.bio, "")

            assert_equal(params[1]['content-disposition'].name, '"pic"')
            assert_equal(params[1]['content-disposition'].filename, '"upload.txt"')
            assert_equal(params[1].body, "LAST ONE\n")
        end)
    end)
end)

