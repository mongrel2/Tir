local mod, meta = {}, {}

--[[
    Simple tnetstrings implementation.
]]

local find = string.find
local sub = string.sub
local len = string.len
local tonumber = tonumber

local function encode(data)
    error('not implemented')
end

local function decode(data)
    local colon_pos = find(data, ':', 1, true)
    local length = tonumber(sub(data, 1, colon_pos - 1))

    local blob_begin = colon_pos + 1
    local blob_end = colon_pos + length
    local blob = sub(data, blob_begin, blob_end)
    local blob_type = sub(data, blob_end + 1, blob_end + 1)

    local data_extra = sub(data, blob_end + 2)
    if len(data_extra) == 0 then data_extra = nil end

    if blob_type == ',' then
        return blob, data_extra
    elseif blob_type == '#' then
        return tonumber(blob), data_extra
    elseif blob_type == '!' then
        if blob == 'true' then
            return true, data_extra
        elseif blob == 'false' then
            return false, data_extra
        else
            error('invalid boolean value')
        end
    elseif blob_type == '~' then
        return nil, data_extra
    elseif blob_type == ']' then
        if length == 0 then return {} end 
        local res = {}
        local n = 1

        local value, extra = nil, blob
        repeat
            value, extra = decode(extra)
            res[n] = value
            n = n + 1
        until not extra

        return res, data_extra
    elseif blob_type == '}' then
        if length == 0 then return {} end 
        local res = {}

        local value, key, extra = nil, nil, blob
        repeat
            key, extra = decode(extra)
            if not type(key) == 'string' then error('keys must be strings') end
            if not extra then error('unbalanced dict') end
            value, extra = decode(extra)

            res[key] = value
        until not extra

        return res, data_extra
    else
        error('invalid type code')
    end
end

mod.decode = decode
mod.encode = encode

return setmetatable(mod, meta)