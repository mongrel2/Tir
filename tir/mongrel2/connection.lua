--[[
# Copyright (c) 2010 Joshua Simmons <simmons.44@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
]]

local json = require 'json'
local zmq = require 'zmq'

local request = require 'mongrel2.request'
local util = require 'mongrel2.util'

local pairs, pcall, setmetatable, tostring = pairs, pcall, setmetatable, tostring
local insert, concat, format, length = table.insert, table.concat, string.format, string.len 

local Connection = {}
Connection.__index = Connection

--[[
    A Connection object manages the connection between your handler
    and a Mongrel2 server (or servers).  It can receive raw requests
    or JSON encoded requests whether from HTTP or MSG request types,
    and it can send individual responses or batch responses either
    raw or as JSON.  It also has a way to encode HTTP responses
    for simplicity since that'll be fairly common.
]]

-- (code) (status)\r\n(headers)\r\n\r\n(body)
local HTTP_FORMAT = 'HTTP/1.1 %s %s\r\n%s\r\n\r\n%s'

local function http_response(body, code, status, headers)
    headers['content-length'] = length(body)
    
    local raw = {}
    for k, v in pairs(headers) do
        insert(raw, format('%s: %s', k, v))
    end
    
    return format(HTTP_FORMAT, code, status, concat(raw, '\r\n'), body)
end

--[[
    Receives a raw mongrel2.request object that you can then work with.
    Upon error while parsing the data, returns nil and an error message.
]]
function Connection:recv()
    local req, err = self.reqs:recv()
    if req then
        return request.parse(req)
    else
        return nil, err
    end
end

--[[
    Same as regular recv, but assumes the body is JSON and 
    creates a new attribute named req.data with the decoded
    payload.

    Normally Request just does this if the METHOD is 'JSON'
    but you can use this to force it for say HTTP requests.

    Upon error while parsing the data, returns nil and an error message.
]]
function Connection:recv_json()
    local recv, err = self:recv()
    if not recv then return nil, err end
    
    if not recv.data then
        local success, data = pcall(json.decode, recv.body)
        if not success then return nil, data end

        recv.data = data
    end

    return recv
end

--[[
    Raw send to the given connection ID at the given uuid, mostly 
    used internally.
]]
function Connection:send(uuid, conn_id, msg)
    conn_id = tostring(conn_id)
    local header = format('%s %d:%s,', uuid, conn_id:len(), conn_id)
    return self.resp:send(header .. ' ' .. msg)
end

--[[
    Does a reply based on the given Request object and message.
    This is easier since the req object contains all the info
    needed to do the proper reply addressing.
]]
function Connection:reply(req, msg)
    return self:send(req.sender, req.conn_id, msg) 
end

--[[
    Same as reply, but tries to convert data to JSON first.
]]
function Connection:reply_json(req, data)
    return self:reply(req, json.encode(data))
end

--[[
    Basic HTTP response mechanism which will take your body,
    any headers you've made, and encode them so that the 
    browser gets them.
]]
function Connection:reply_http(req, body, code, status, headers)
    code = code or 200
    status = status or 'OK'
    headers = headers or {}
    return self:reply(req, http_response(body, code, status, headers))
end

--[[
    This lets you send a single message to many currently
    connected clients.  There's a MAX_IDENTS that you should
    not exceed, so chunk your targets as needed.  Each target
    will receive the message once by Mongrel2, but you don't have
    to loop which cuts down on reply volume.
]]
function Connection:deliver(uuid, idents, data)
    return self:send(uuid, concat(idents, ' '), data)
end

--[[
    Same as deliver, but converts to JSON first.
]]
function Connection:deliver_json(uuid, idents, data)
    return self:deliver(uuid, idents, json.encode(data))
end

--[[
    Same as deliver, but builds a HTTP response.
]]
function Connection:deliver_http(uuid, idents, body, code, status, headers)
    code = code or 200
    status = status or 'OK'
    headers = headers or {}
    return self:deliver(uuid, idents, http_response(body, code, status, headers))
end

--[[
-- Tells Mongrel2 to explicitly close the HTTP connection.
--]]
function Connection:close(req)
    return self:reply(req, "")
end

--[[
-- Sends and explicit close to multiple idents with a single message.
--]]
function Connection:deliver_close(uuid, idents)
    return self:deliver(uuid, idents, "")
end

--[[
    Creates a new connection object.
    Internal use only, call ctx:new_context instead.
]]
local function new(ctx, sender_id, sub_addr, pub_addr)
    local good, err

    -- Create and connect to the PULL (request) socket.
    local reqs, err = ctx:socket(zmq.PULL);
    if not reqs then return nil, err end

    good, err = reqs:connect(sub_addr)
    if not good then return nil, err end

    -- Create and connect to the PUB (response) socket.
    local resp, err = ctx:socket(zmq.PUB)
    if not resp then return nil, err end

    good, err = resp:connect(pub_addr)
    if not good then return nil, err end

    good, err = resp:setopt(zmq.IDENTITY, sender_id)
    if not good then return nil, err end

    -- Build the object and give it a metatable.
    local obj = {
        ctx = ctx;
        sender_id = sender_id;

        sub_addr = sub_addr;
        pub_addr = pub_addr;

        reqs = reqs;
        resp = resp;
    }

    return setmetatable(obj, Connection)
end

return {
    new = new;
}
