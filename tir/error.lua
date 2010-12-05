
-- The basic error page HTML.  Nothing fancy, but you can change it if you want.
local ERROR_PAGE = compile_view [[
<html><head><title>Tir Error</title></head> 
<body>
<p>There was an error processing your request.</p>
<h1>Stack Trace</h1>
<pre>
{{ err }}
</pre>
<h1>Source Code</h1>
<pre>
{{ source }}
</pre>
<h1>Request</h1>
<pre>
{{ request }}
</pre>
</body>
</html>
]]

-- Reports errors back to the browser so the user has something to work with.
function report_error(conn, request, err, state)
    local pretty_req = pretty_json(request)
    local trace = debug.traceback(state.controller, err)
    local info
    local source = nil

    if state.stateless then
        info = debug.getinfo(state.main)
    else
        info = debug.getinfo(state.controller, state.main)
    end

    if info.source:match("@.+$") then
        source = load_lines(info.short_src, info.linedefined, info.lastlinedefined)
    else
        source = info.source
    end

    local page = ERROR_PAGE {err=trace, source=source, request=pretty_req}
    conn:reply_http(request, page, 500, "Internal Server Error")
    print("ERROR", err)
end

