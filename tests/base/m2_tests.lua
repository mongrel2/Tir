require 'tir.engine'


context("Tir", function()
    context("m2", function()
        test("load_config", function()
            local config = {config_db = "tests/data/config.sqlite", route="/arc"}

            Tir.M2.load_config(config)
            assert_not_nil(config.sub_addr)
            assert_not_nil(config.pub_addr)

            assert_equal(config.sub_addr, 'tcp://127.0.0.1:9990')
            assert_equal(config.pub_addr, 'tcp://127.0.0.1:9989')

            config.host = "(.+)"
            Tir.M2.load_config(config)
            assert_equal(config.sub_addr, 'tcp://127.0.0.1:9990')
            assert_equal(config.pub_addr, 'tcp://127.0.0.1:9989')

        end)
    end)
end)

