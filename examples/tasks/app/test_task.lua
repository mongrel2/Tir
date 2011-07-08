require 'tir.engine'

function test(args)
    Tir.dump(args)
end

Tir.Task.start { main = test, spec = 'ipc://run/photos' }

