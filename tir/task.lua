
module('Tir.Task', package.seeall)

local IO_THREADS = 1

local zmq = require 'zmq'
local json = require 'json'

function start(config)
    assert(config.spec, "You need to at least set spec = to your 0MQ socket spec.")
    assert(config.main, "You must set a main function.")

    local ctx = assert(zmq.init(config.io_threads or IO_THREADS))
    local conn = assert(ctx:socket(config.socket_type or zmq.SUB))
    local main = config.main
    conn:setopt(zmq.SUBSCRIBE, config.subscribe or '')
    conn:bind(config.spec)

    if config.recv_ident then
        conn:setopt(zmq.IDENTITY, config.recv_ident)
    end

    print("BACKGROUND TASK " .. config.spec .. " STARTED.")

    while true do
        local data = assert(conn:recv())

        if data then
            local prefix, payload = data:match("^([%w_]+) (.+)$")
            assert(prefix, "Invalid task request, no prefix given: " .. data)
            assert(payload, "Invalid task request, no payload: " .. data)
            local req = assert(json.decode(payload))

            main(req)
        else
            main(data)
        end
    end
end

function connect(config)
    assert(config.spec, "You need to at least set spec = to your 0MQ socket spec.")

    local ctx = assert(zmq.init(config.io_threads or IO_THREADS))
    local conn = assert(ctx:socket(config.socket_type or zmq.PUB))
    conn:connect(config.spec)

    if config.send_ident then
        conn:setopt(zmq.IDENTITY, config.send_ident)
    end

    local TaskConn = {
        ctx = ctx,
        conn = conn,
        config = config
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

