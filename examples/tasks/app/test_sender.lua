require 'tir/engine'
require 'posix'

local conn = Tir.Task.connect('ipc://run/photos')

function main(web, req)
    conn:send('photo', req.headers)
    web:ok()
end

Tir.stateless {route='/Task', main=main}
