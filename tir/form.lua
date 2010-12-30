module('Tir', package.seeall)

local ENCODING_MATCH = '^%s-([%w/%-]+);*(.*)$'
local URL_ENCODED_FORM = 'application/x-www-form-urlencoded'
local MULTIPART_ENCODED_FORM = 'multipart/form-data'

function parse_headers(head)
    local result = {}
    head = head .. '\r\n'

    for key, val in head:gmatch('%s*(.-):%s*(.-)\r\n') do
        result[key:lower()] = url_parse(val, ';')
    end

    return result
end


function extract_multipart(body, params)
    -- very simplistic and will require the whole file be loaded into ram
    params = params .. ';'
    local boundary = '%-%-' .. params:match('^.*boundary=(.-);.*$'):gsub('%-', '%%-')
    local results = {}

    -- go through each part, and break out the headers from the 
    for part in body:gmatch('(.-)' .. boundary) do
        local head, piece = part:match('^(.-)\r\n\r\n(.*)\r\n$')

        if head then
            head = parse_headers(head)

            local cdisp = head['content-disposition']

            if cdisp and cdisp.name and cdisp[1] == 'form-data' and not head['content-type'] then
                results[cdisp.name:match('"(.-)"')] = piece
            else
                head.body = piece
                results[#results + 1] = head
            end
        end
    end

    return results
end

-- Parses a form out of the request, figuring out if it's something that
-- we can handle.  It might not handle all the really weird ways forms are
-- encoded, so YYMV.
function parse_form(req)
    local headers = req.headers
    local params = {}

    if headers.METHOD == 'GET' then
        if headers.QUERY then
            params = url_parse(headers.QUERY)
        end
    elseif headers.METHOD == 'POST' then
        local ctype = headers['content-type'] or ""
        local encoding, encparams = ctype:match(ENCODING_MATCH)
        encoding = encoding:lower()

        if encoding == URL_ENCODED_FORM then
            if req.body then
                params = url_parse(req.body)
            end
        elseif encoding == MULTIPART_ENCODED_FORM then
            params = extract_multipart(req.body, encparams)
            params.multipart = true
        else
            error("POST RECEIVED BUT NO CONTENT TYPE WE UNDERSTAND: " .. ctype)
        end
    end

    params.__session = req.session_id

    return params
end


-- Creates Form objects for validating form input in the coroutines.
function form(required_fields)
    local Form = {
        required_fields = required_fields
    }

    function Form:requires(params)
        local errors = {}
        local had_errors = false

        for _, field in ipairs(self.required_fields) do
            if not params[field] or #params[field] == 0 then
                errors[field] = 'This is required.'
                had_errors = true
            end
        end

        if had_errors then
            params.errors = json.encode(errors)
            return false
        else
            params.errors = nil
            return true
        end
    end

    function Form:clear(params)
        params.errors = nil
    end

    function Form:valid(params)
        local has_required = self:requires(params)

        if has_required and self.required_fields.validator then
            return self.required_fields.validator(params)
        else
            return has_required
        end
    end

    function Form:parse(req)
        return parse_form(req)
    end

    return Form
end

-- Mostly used in tir/testing.lua
function form_encode(data, sep)
    local result = {}

    for k,v in pairs(data) do
        result[#result + 1] = Tir.url_encode(k) .. '=' .. Tir.url_encode(v)
    end

    return table.concat(result, sep or '&')
end

