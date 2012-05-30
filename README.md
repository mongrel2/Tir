Tir Web Framework: The State Agnostic Lua Micro-Framework
=========================================================

Tir is an experimental web framework for the [Mongrel2 webserver](http://mongrel2.org/) and Lua
programming language. The purpose of Tir is to play with the idea of a State
Agnostic web framework. Tir lets you create handlers that work in various
configurations as needed by your application requirements. You create your
application using a [natural coroutine style](#natural-style) handler, 
then make another part [stateless](#stateless-style), 
and still have other parts using an [evented/callback style](#evented-style).

Getting Started
---------------

Tir is very alpha, but it is being used on a few projects. Feel free to grab
the code and if you want to help, then contact zedshaw-AT-zedshaw.com for more
information.  The source to Tir is available at
http://tir.mongrel2.org/downloads/tir-0.9-1.tar.gz.

Install instructions and more information can be found on the Tir website at
http://tir.mongrel2.org


Tir's Philosophy
----------------

Tir's philosophy is that the framework creator shouldn't be shoving stateful/
stateless dogma in your face, and that it's possible to support various state
management styles. Tir allows you to use different state management strategies
for different interfaces you need to design.

* If a part of your application is a complex process, then Natural Style is the
  way to go.
* If there's a single URL service then Stateless Style is the easiest.
* If you have a URL+action for say a REST API then Evented Style works great.

The point though is that different problems are best solved with different
state management.

Natural Style
-------------

I'm calling the coroutine based handlers "Natural Style" because you write the
code for them in a more natural way, as if you don't need to worry about
routing and state management. You can code up entire complex processes and
interactions using the natural style very easily. For example, pagination is
difficult in stateless servers, but it's just a repeat/until loop in natural
style.
By default, handlers are natural style and maintain a coroutine for each user
and let you write your code using phrases like `prompt`, `recv`, `page`, and
`send`.

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
---------------

Handlers can be made "stateless" and they'll work like coroutine handlers, but
not retain any state. These are good for one-shot operations and simpler
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
-------------

Tir also supports the alternative "evented" style, which means that URLs are
mapped to callback functions in your handler. A simple URL pattern is used to
transform your `/Route/action` style URLs into a function to call. Best of all,
evented operation can be combined with stateless (the default) or coroutines,
so you can easily refactor complex URL schemes if you need:

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

In this style, `Manage.form` is run and then your handlers receive the results to
work with right away. You can even change the routing pattern if you don't like
what I've chosen, or need even more complexity in your life.

Simple Templating Language
--------------------------

Tir uses embedded Lua as it's templating language, which means you get a real
language and not some crippled one someone smarter than you thinks you should be
using. And Lua already looks like most of the nice template languages out
there:

<pre>
  {% if #results &gt; 0 then %}
  &lt;ul&gt;
      {% for _,result in ipairs(results) do %}
      &lt;li&gt;{{ result }}&lt;/li&gt;
      {% end %}
  &lt;/ul&gt;
  {% else %}
  &lt;p&gt;We'll add "{{ q }}" as a new one.&lt;/p&gt;
  {% end %}
</pre>

Multiple Little Processes
-------------------------

Tir also uses ZeroMQ and Mongrel2 to run the application as a set of small
processes for each major routing, rather than one monolithic process. In the
above two examples, each `Tir.start` line is a single process.
You can also build on this to flex and warp the size of your processes as you
need, and locate them or cluster them however you like. By default it shoots
for small little processes, but nothing prevents you from doing others.

Builtin Background Tasks
------------------------

`Tir.Task` lets you create and connect to ready to run 0MQ background task
processes so you can offload long running tasks and avoid holding up web
requests. They're designed to be very easy to use, but still flexible enough to
let you do what you need. By default they use PUB/SUB sockets, but you can
change that with a setting. You can also put the background tasks on clusters
of machines and nearly anything else you need to do. Messages are simply just
JSON encoded Lua structures.
Here's a Task that just dumps it's args.

<pre>
  require 'tir/engine'

  function test(args)
      Tir.dump(args)
  end

  Tir.Task.start { main = test, spec = 'ipc://run/photos' }
</pre>

And here's a sample Handler that can talk to it:

<pre>
  require 'tir/engine'

  local conn = Tir.Task.connect { spec = 'ipc://run/photos' }

  function main(web, req)
      conn:send('photo', req.headers)
      web:ok()
  end

  Tir.stateless {route='/Task', main=main}
</pre>

Unit Test Support
-----------------

New in 0.9, Tir now has decent unit testing in the tir/testing library and
there's a sample test in the [Getting Started guide](http://tir.mongrel2.org/wiki/quick_start.html)
that shows how it's done.

Async Ready
-----------

Because Tir uses Mongrel2 it already support async operation, streaming,
regular HTTP, HTTP long poll, and flash/jssockets.

No ORM
------

Tir comes without an ORM by default. People would probably hate any ORM I wrote
and there's plenty of options you can add.

No Core
-------

This isn't really a Tir feature, but don't you hate it when there's bugs in your core
libraries and that guy who "owns" the broken library refuses to fix it? Me too,
that's why Lua and LuaRocks are awesome. You get a tight core language that's
completely described in a few HTML pages, and can install all the platform
libraries you need with LuaRocks.
No more gatekeepers with Lua.
