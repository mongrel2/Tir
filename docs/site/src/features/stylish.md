Stylish State Management
=======================

Tir's philosophy is that the framework creator shouldn't be shoving
stateful/stateless dogma in your face, and that it's possible to support
various state management styles.  Tir allows you to use different state management 
strategies for different interfaces you need to design.

* If a part of your application is a complex process, then <b>Natural Style</b> is the way to go.   
* If there's a single URL service then <b>Stateless Style</b> is the easiest.
* If you have a URL+action for say a REST API then <b>Evented Style</b> works great.

The point though is that different problems are best solved with different state
management.

Natural Style
=============

I'm calling the coroutine based handlers "Natural Style" because you write the
code for them in a more natural way, as if you don't need to worry about routing
and state management.  You can code up entire complex processes and interactions
using the natural style very easily.  For example, pagination is difficult in
stateless servers, but it's just a <b>repeat/until</b> loop in natural style.

By default, handlers are natural style and maintain a coroutine for each user
and let you write your code using phrases like "prompt", "recv", "page", and "send".

<pre>
local login_page = Tir.view("login.html")
local login_form = Tir.form { 'login_name', 'password'}

local function login(web, req)
    local params = login_form:parse(req)

    repeat
        params = web:prompt(login_page {form=params, logged_in=false})
    until login_form:valid(params)
    
    return web:redirect('/')
end

Tir.start {route='/Login', main=login}
</pre>


Stateless Style
===============


Handlers can be made "stateless" and they'll work like coroutine handlers, but
not retain any state.  These are good for one-shot operations and simpler
actions that don't need much routing.

<pre>
local search_page = Tir.view("search.html")
local search_form = Tir.form {"q"}

local function search(web, req)
    local params = search_form:parse(req)
    local q = params.q
    local results = {}

    if search_form:valid(params) then 
        local pattern = ".*" .. q:upper() .. ".*";

        for i, cat in ipairs(categories) do
            if cat:upper():match(pattern) then
                results[#results + 1] = cat
            end
        end
    end

    web:page(search_page {results=results, q=q})
end

Tir.stateless {route='/Search', main=search}
</pre>

Evented Style
=============

Tir also supports the alternative "evented" style, which means that URLs are
mapped to callback functions in your handler.  A simple URL pattern is used to
transform your /Route/action style URLs into a function to call.  Best of all,
evented operation can be combined with stateless (the default) or
coroutines, so you can easily refactor complex URL schemes if you
need:

<pre>
local Manage = {
    form = Tir.form {"id", "action"}
}

function Manage.people(web, req, params)
    -- Do whatever managing people does.
end

function Manage.cats(web, req, params)
    -- Whatever managing cats means, if that's possible.
end

function Manage.dogs(web, req, params)
    -- Ah way easier to manage dogs.
end

Manage.config = {
    route='/Manage', 
}

Tir.evented(Manage)
</pre>

In this style, Manage.form is run and then your handlers receive the results to
work with right away.  You can even change the routing pattern if you don't
like what I've chosen, or need even more complexity in your life.

