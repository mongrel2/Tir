require 'json'

-- Helper function that does a debug dump of the given data.
function dump(data)
    json.util.printValue({['*'] = data}, '*')
end

-- Helper function that loads a file into ram.
function load_file(from_dir, name)
    local intmp = assert(io.open(from_dir .. name, 'r'))
    local content = intmp:read('*a')
    intmp:close()

    return content
end

function update(target, source, keys)
    if keys then 
        for _, key in ipairs(keys) do
            target[key] = source[key]
        end
    else
        for k,v in pairs(source) do
            target[k] = v
        end
    end
end


-- useful for tables and params and stuff
function clone(source, keys)
    local target = {}
    update(target, source, keys)
    return target
end


-- Simplistic HTML escaping.
function escape(s)
    if s == nil then return '' end

    local esc, i = s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
    return esc
end

-- Simplistic URL decoding that can handle + space encoding too.
function url_decode(data)
    return data:gsub("%+", ' '):gsub('%%(%x%x)', function (s)
        return string.char(tonumber(s, 16))
    end)
end

-- Basic URL parsing that handles simple key=value&key=value setups
-- and decodes both key and value.
function url_parse(data, sep)
    local result = {}
    sep = sep or '&'
    data = data .. sep

    for piece in data:gmatch("(.-)" .. sep) do
        local k,v = piece:match("%s*(.-)%s*=(.*)")

        if k then
            result[url_decode(k)] = url_decode(v)
        else
            result[#result + 1] = url_decode(piece)
        end
    end

    return result
end


-- Used for dumping json so it can be displayed to someone.
function pretty_json(tab)
    return json.encode(tab):gsub('","', '",\n"')
end


-- Loads a source file, but converts it with line numbering only showing
-- from firstline to lastline.
function load_lines(source, firstline, lastline)
    local f = io.open(source)
    local lines = {}
    local i = 0

    -- TODO: this seems kind of dumb, probably a better way to do this
    for line in f:lines() do
        i = i + 1

        if i >= firstline and i <= lastline then
            lines[#lines+1] = ("%0.4d: %s"):format(i, line)
        end
    end

    return table.concat(lines,'\n')
end


