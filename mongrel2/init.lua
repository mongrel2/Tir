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

local zmq = require 'zmq'

local connection = require 'mongrel2.connection'
local util = require 'mongrel2.util'

local setmetatable = setmetatable

local Context = {}
Context.__index = Context

function Context:new_connection(sender_id, sub_addr, pub_addr)
    return connection.new(self.ctx, sender_id, sub_addr, pub_addr)
end

function Context:term()
    return self.ctx:term()
end

local function new(io_threads)
    io_threads = io_threads or 1

    local ctx, err = zmq.init(io_threads)

    if not ctx then return nil, err end

    local obj = {
        ctx = ctx;
    }

    return setmetatable(obj, Context)
end

return {
    new = new;
}
