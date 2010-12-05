require 'mongrel2'
require 'luasql.sqlite3'

module('Tir.M2', package.seeall)

local CONFIG_SQL = "select send_spec, recv_spec from handler where id=(select target_id from route where target_type='handler' and path='%s')"


-- Loads the Handler config out of the Mongrel2 sqlite config so we don't
-- have to specify it over and over.
function load_config(config)
    local env = assert(luasql.sqlite3())
    local conn = assert(env:connect(config.config_db))
    local cur = assert(conn:execute(CONFIG_SQL:format(config.route)))
    local row = cur:fetch({}, "a")

    assert(row, "Did not find anything for route " .. config.route)
    config.sub_addr = row.send_spec
    config.pub_addr = row.recv_spec

    cur:close()
    conn:close()
    env:close()
end



function connect(config)
    -- Connect to the Mongrel2 server
    print("CONNECTING", config.route, config.sender_id, config.sub_addr, config.pub_addr)

    local ctx = mongrel2.new(config.io_threads)
    local conn = ctx:new_connection(config.sender_id, config.sub_addr, config.pub_addr)

    assert(conn, "Failed to start Mongrel2 connection.")

    return conn
end
