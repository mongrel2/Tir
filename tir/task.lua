
module('Tir.Task', package.seeall)

local IO_THREADS = 1

local zmq = require 'zmq'
local json = require 'json'

function start(main, spec, subscribe, recv_ident)
    local ctx = assert(zmq.init(IO_THREADS))
    local conn = assert(ctx:socket(zmq.SUB))
    conn:setopt(zmq.SUBSCRIBE, subscribe or '')
    conn:bind(spec)

    if recv_ident then
        conn:setopt(zmq.IDENTITY, recv_ident)
    end

    while true do
        local data = assert(conn:recv())

        if data then
            local prefix, payload = data:match("^(%w+) (.+)$")
            local req = assert(json.decode(payload))
            main(req)
        else
            main(data)
        end
    end
end

function connect(spec, send_ident)
    local ctx = assert(zmq.init(IO_THREADS))
    local conn = assert(ctx:socket(zmq.PUB))
    conn:connect(spec)

    if send_ident then
        conn:setopt(zmq.IDENTITY, send_ident)
    end

    local TaskConn = {
        ctx = ctx,
        conn = conn,
        spec = spec,
        send_ident = send_ident
    }

    function TaskConn:send(target, data)
        self.conn:send(target .. ' ' .. json.encode(data))
    end

    function TaskConn:term()
        self.conn:close()
        self.ctx:term()
    end

    return TaskConn
end

