require 'md5'
require 'posix'

module('Tir', package.seeall)

local UUID_TYPE = 'random'
local BIG_EXPIRE_TIME = 20
local PID = tonumber(posix.getpid().pid)
local HOSTID = posix.hostid()
local RNG_BYTES = 8 -- 64 bits of randomness should be good
local RNG_DEVICE = '/dev/urandom'

function make_rng()
    if posix.access(RNG_DEVICE) then
        local urandom = assert(io.open(RNG_DEVICE))

        return function()
            return md5.sumhexa(urandom:read(RNG_BYTES) .. os.time() .. PID .. HOSTID)
        end
    else
        print("WARNING! YOU DO NOT HAVE " .. RNG_DEVICE .. ". Your session keys aren't very secure.")
        math.randomseed(os.time() + PID + HOSTID)

        return function()
            return md5.sumhexa(tostring(math.random()) .. os.time() .. PID .. HOSTID)
        end
    end
end

local RNG = make_rng()

function make_session_id()
    return 'APP-' .. RNG()
end

function make_expires()
    local temp = os.date("*t", os.time())
    temp.year = temp.year + BIG_EXPIRE_TIME
    return os.time(temp)
end

function make_session_cookie(ident)
	local cookie = {}
	cookie.key = 'session'
	cookie.value = ident or make_session_id()
	cookie.version = 1
	cookie.path = '/'
	cookie.expires = make_expires()
	return cookie
end

function parse_session_id(cookie)
    if not cookie then return nil end

	local cookie = parse_http_cookie(cookie)
	
	return cookie.session[1]
end


function json_ident(req)
    local ident = req.data.session_id

    if not ident then
        ident = make_session_id()
        req.data.session_id = ident
    end

    req.session_id = ident
    return ident
end


function http_cookie_ident(req)
    local ident = parse_session_id(req.headers['cookie'])
    if not ident then
        ident = make_session_id()
        local cookie = make_session_cookie(ident)

		set_http_cookie(req, cookie)
        req.session_id = ident
    end

    req.session_id = ident
    return ident
end

-- This is the default way an engine identifies a connection, using
-- cookies.  You can change this to use just the connection id too.
-- It will handle either JSON requests or HTTP requests and it will
-- craft cookies for you.
function default_ident(req)
    if req.headers.METHOD == "JSON" then
        return json_ident(req)
    else
        return http_cookie_ident(req)
    end
end
