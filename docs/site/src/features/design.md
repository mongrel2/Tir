Simple Design
=============

Tir is an experimental web framework for the <a
href="http://mongrel2.org/">Mongrel2 webserver</a> and <a
href="http://www.lua.org/">Lua programming language</a>.  The purpose of Tir is
to play with the idea of a *State Agnostic* web framework.  In addition
to the [ways you can manage state](/features/stylish.html), Tir supports
all the major features you need from a web framework in just 1300 lines
of Lua code.  Here's just some of them.

Simple Templating Language
=========

Tir uses embedded Lua as it's templating language, which means you get a real
language and not some crippled one someone smarter than you think you
*should* be using.  And Lua already looks like most of the nice template
languages out there:

<pre>
{% if #results > 0 then %}
&lt;ul&gt;
    {% for _,result in ipairs(results) do %}
    &lt;li&gt;{{ result }}&lt;/li&gt;
    {% end %}
&lt;/ul&gt;
{% else %}
&lt;p&gt;We'll add "{{ q }}" as a new one.&lt;/p&gt;
{% end %}
</pre>

The best part of this template language is that it's just Lua,
but looks like [Jinja2](http://jinja.pocoo.org/docs/)
or [Django](https://docs.djangoproject.com/en/dev/ref/templates/api/) but
it's a *real* programming language.  In fact, here's the tiny bit of code
that implements the template language:

<pre>
-- Used in template parsing to figure out what each {} does.
local VIEW_ACTIONS = {
    ['{%'] = function(code)
        return code
    end,

    ['{{'] = function(code)
        return ('_result[#_result+1] = %s'):format(code)
    end,

    ['{('] = function(code)
        return ([[ 
            if not _children[%s] then
                _children[%s] = Tir.view(%s)
            end

            _result[#_result+1] = _children[%s](getfenv())
        ]]):format(code, code, code, code)
    end,

    ['{&lt;'] = function(code)
        return ('_result[#_result+1] =  Tir.escape(%s)'):format(code)
    end,
}
</pre>

Which also means you can easily extend Tir's templates to support other
features you need by just adding some closures to a single table.


Multiple Little Processes
=========

Tir also uses <a href="http://zeromq.org">ZeroMQ</a> and <a
href="http://mongrel2.org">Mongrel2</a> to run the application as a set of
small processes for each major routing, rather than one monolithic process.  In
the above two examples, each *Tir.start* line is a single process.

You can also build on this to flex and warp the size of your processes as you
need, and locate them or cluster them however you like.  By default it shoots
for small little processes, but nothing prevents you from doing others.

Builtin Background Tasks
=========

Tir.Task lets you create and connect to ready to run 0MQ background task
processes so you can offload long running tasks and avoid holding up web
requests.  They're designed to be very easy to use, but still flexible enough
to let you do what you need.  By default they use PUB/SUB sockets, but you
can change that with a setting.  You can also put the background tasks on
clusters of machines and nearly anything else you need to do.  Messages are
simply just JSON encoded Lua structures.

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
=========

New in 0.9, Tir now has decent unit testing in the *tir/testing* library
and there's a sample test in the [quick start](/features/quick_start.html) guide that shows how it's
done.

Async Ready
=========

Because Tir uses Mongrel2 it already support async operation, streaming,
regular HTTP, HTTP long poll, and flash/jssockets.


No ORM
=========

Tir comes *without* an ORM by default.  People would probably hate any ORM I
wrote and there's plenty of options you can add.


No Core
=========

This isn't really a Tir feature, but do you hate when there's bugs in your core
libraries and that guy who "owns" the broken library refuses to fix it?  Me
too, that's why <a href="http://lua.org">Lua</a> and <a
href="http://luarocks.org/">LuaRocks</a> are awesome.  You get a tight core
language that's completely described <a
href="http://www.lua.org/manual/5.1/">in a few HTML pages</a> and then install
all the platform libraries you need with LuaRocks.

No more gatekeepers with Lua.

