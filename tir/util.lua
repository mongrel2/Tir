

module('Tir', package.seeall)

require 'json'


function table_print(tt, indent, done)
  local done = done or {}
  local indent = indent or 0
  local space = string.rep(" ", indent)

  if type(tt) == "table" then
    local sb = {}

    for key, value in pairs(tt) do
      table.insert(sb, space) -- indent it

      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, key .. " = {\n");
        table.insert(sb, table_print(value, indent + 2, done))
        table.insert(sb, space) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\" ", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring(key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string(data)
    if "nil" == type(data) then
        return tostring(nil)
    elseif "table" == type(data) then
        return table_print(data)
    elseif  "string" == type(data) then
        return data
    else
        return tostring(data)
    end
end

function dump(data, name)
    print(to_string({name or "*", data}))
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

-- Simplistic URL encoding
function url_encode(data)
    return data:gsub("\n","\r\n"):gsub("([^%w%-%-%.])", 
        function (c) return ("%%%02X"):format(string.byte(c)) 
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


-- Parses a cookie string into a table
-- Note:  If the cookie string contains multiple cookies with the same key,
-- only one of them will be returned in the resulting table
function parse_cookie(cookie)
	local cookie_str = string.gsub(cookie, "%s*;%s*", ";")   -- remove extra spaces
  
	local cookies = {}
  
	for k, v in string.gmatch(cookie_str, "([^;]+)=([^;]+)") do
		cookies[k] = v
	end

	return cookies		
end
