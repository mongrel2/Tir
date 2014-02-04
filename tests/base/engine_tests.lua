require 'tir.engine'


function fake_main()
    print("TEST")
end

context("Tir", function()
    context("engine", function()
        test("start", function()
            Tir.run = function() return true end
            Tir.M2.connect = function() return true end
             
            local config = {config_file = 'tests/data/config.lua', route = '/arc'}
            Tir.start(config)
    
            assert_equal('tcp://127.0.0.1:9990', config.sub_addr)
            assert_equal('tcp://127.0.0.1:9989', config.pub_addr)
        end)

        test("start-overide", function()
            Tir.run = function() return true end
            Tir.M2.connect = function() return true end
             
            local config = {config_file = 'tests/data/config.lua', route = '/arc', pub_addr = 'tcp://10.234.56.71:9990', sub_addr = 'tcp://10.234.56.71:9989'}
            Tir.start(config)
    
            assert_equal('tcp://10.234.56.71:9990', config.pub_addr)
            assert_equal('tcp://10.234.56.71:9989', config.sub_addr)
            end)        
    end)
end)

