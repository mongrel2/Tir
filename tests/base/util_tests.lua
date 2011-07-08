require 'tir.engine'

context("Tir", function()
    context("util", function()
        test("dump", function()
            Tir.dump("hello")
            Tir.dump(true)
            Tir.dump({test=1, apple="hi"})
        end)

        test("load_file", function()
            local data = Tir.load_file("bin/", "tir")
            assert_not_nil(data)
        end)

        test("update", function()
            local target = {test=1}
            local source = {test=2, extra=3}
            Tir.update(target, source)
            assert_equal(target.test, source.test)
            assert_equal(target.extra, source.extra)

            local target = {test=1}
            Tir.update(target, source, {"extra"})
            assert_not_equal(target.test, source.test)
            assert_equal(target.extra, source.extra)
        end)

        test("clone", function()
            local target = {test=1, hello=2}
            local source = Tir.clone(target)
            assert_equal(target.test, source.test)
            assert_equal(target.hello, source.hello)

            local source = Tir.clone(target, {"hello"})
            assert_nil(source.test)
            assert_equal(target.hello, source.hello)
        end)

        test("escape", function()
            assert_equal(Tir.escape("<div><p>Hello & Stuff</p></div>"), "&lt;div&gt;&lt;p&gt;Hello &amp; Stuff&lt;/p&gt;&lt;/div&gt;")
        end)

        test("url_decode", function()
            assert_equal(Tir.url_decode("/This%52%53++%20+", ""), "/ThisRS    ")
        end)

        test("url_parse", function()
            local expect = {test='1', pass="   floor"}
            local parsed = Tir.url_parse("test=1&pass=%20%20+floor")
            assert_equal(expect.test, parsed.test)
            assert_equal(expect.pass, parsed.pass)

            local parsed = Tir.url_parse("test=1; pass=%20%20+floor", ';')
            assert_equal(expect.test, parsed.test)
            assert_equal(expect.pass, parsed.pass)

            local parsed = Tir.url_parse("test=1, pass=%20%20+floor", ',')
            assert_equal(expect.test, parsed.test)
            assert_equal(expect.pass, parsed.pass)
        end)

        test("load_lines", function()
            local source = Tir.load_lines("tir/util.lua", 76, 76)
            assert_match('0076: .*', source)
        end)
    end)
end)

