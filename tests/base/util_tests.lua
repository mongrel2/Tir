require 'tir/engine'

context("Tir", function()
    context("util", function()
        test("dump can dump random things", function()
            Tir.dump("hello")
            Tir.dump(true)
            Tir.dump({test=1, apple="hi"})

        end)
    end)
end)

