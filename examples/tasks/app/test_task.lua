require 'tir/engine'

function test(args)
    Tir.dump(args)
end

Tir.Task.start(test, 'ipc://run/photos')

