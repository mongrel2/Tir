local mongrel2 = require 'tir.mongrel2.init'
mongrel2.config = require 'tir.mongrel2.config'

module('Tir.M2', package.seeall)

function find_handler(m2conf, route, host_name)
    host_name = host_name or m2conf.servers[1].default_host

    for _, server in ipairs(m2conf.servers) do
        for _, host in ipairs(server.hosts) do
            if host.name == host_name then
                return host.routes[route]
            end
        end
    end

    return nil
end

-- Loads the Handler config out of the Mongrel2 sqlite config so we don't
-- have to specify it over and over.
function load_config(config)
    local m2conf = assert(mongrel2.config.read(config.config_db),
        "Failed to load the mongrel2 config: " .. config.config_db)

    local handler = find_handler(m2conf, config.route, config.host)
    assert(handler, "Failed to find route: " .. config.route ..
            ". Make sure you set config.host to a host in your mongrel2.conf.")

    config.sub_addr = handler.send_spec
    config.pub_addr = handler.recv_spec
end



function connect(config)
    -- Connect to the Mongrel2 server
    print("CONNECTING", config.route, config.sender_id, config.sub_addr, config.pub_addr)

    local ctx = mongrel2.new(config.io_threads)
    local conn = ctx:new_connection(config.sender_id, config.sub_addr, config.pub_addr)

    assert(conn, "Failed to start Mongrel2 connection.")

    return conn
end


