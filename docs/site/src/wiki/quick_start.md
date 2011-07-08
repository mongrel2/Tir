Your First Tir Application
==========================

Tir right now is probably a little hard to setup, so make sure you went through
the [Install](/wiki/install.html) instructions before you do anything.  Once
you have Tir installed you can grab the <a href="/downloads/">examples
downloads</a> source to get started.

The Arc Challenge Example
=========================

What we'll do next is get the *examples/arc_challenge* started.  This
example is a demonstration of Tir doing the <a
href="http://www.paulgraham.com/arcchallenge.html">Arc Challenge</a> using the
a simple natural style handler.

To get it working, first you have to grab the source and get Mongrel2 running:

<pre>
# get the examples
curl -O http://tir.mongrel2.org/downloads/tir-examples-VERSION.tar.gz

# untar them and go into the arc_challenge
tar -xzvf tir-examples-VERSION.tar.gz
cd examples/arc_challenge/

# get mongrel2 setup
m2sh load -config conf/mongrel2.conf -db conf/config.sqlite
mkdir run logs tmp
m2sh start -db conf/config.sqlite -every
</pre>

Leave that running in a window, and now you can start the Tir app:

<pre>
tir start
</pre>

Which should look like this:

<pre>
Started ./app/arc_challenge.lua PID 3301
CONNECTING	/Arc	38f857b8-cbaa-4b58-9271-0d36c27813c4 \
    tcp://127.0.0.1:9990	tcp://127.0.0.1:9989
</pre>

Finally, go to http://localhost:6767/Arc to try it out.

Unit Tests
==========

There's a "complete enough" unit testing framework that should work with any of the Lua
testing framework out there.  If you require 'tir/testing' in a test file then you get
the ability to run fake browsers against your handlers and have the tests validate
that they're working.  The framework also supports doing Xhr requests (JSON, AJAX),
form submits, URL clicks, checking return codes, and matching patterns in content.

To run the tests, make sure that <a href="https://github.com/norman/telescope">Telescope</a>
is installed then run:

<pre>
$ tir test
</pre>

Your output should look like this:

<pre>
---------------- TESTS -----------------
REQUEST /Arc:2	Sun Jan  9 11:55:23 2011	/Arc	GET	APP-XXXXX
REQUEST /Arc:2	Sun Jan  9 11:55:23 2011	/Arc	POST	APP-XXXXX
REQUEST /Arc:2	Sun Jan  9 11:55:23 2011	/Arc	GET	APP-XXXXX
REQUEST /Arc:2	Sun Jan  9 11:55:23 2011	/Arc	GET	APP-XXXXX
1 test 1 passed 2 assertions 0 failed 0 errors 0 unassertive 0 pending
</pre>

Unit tests are very simple, and just do basic assert calls to make sure everything is
working right.  Here's the test code for what you just ran from *tests/app_tests/arc_challenge_tests.lua*:

<pre>
require 'tir/testing'
require 'app/arc_challenge'

context("Arc Challenge", function()
    context("interaction", function()
        test("do it", function()
            local tester = Tir.Tests.browser("tester")

            -- click assumes you want a 200 all the time and just returns
            -- the response it got
            local resp = tester:click("/Arc")
            assert_match(".*Tir Arc Challenge.*form.*", resp.body) 

            -- you can also pass what you expect in as another parameter
            -- with values that are converted to strings and then pattern matched
            resp = tester:submit("/Arc", {msg = "Hello!"}, {body = ".*click here.*"})

            resp = tester:click("/Arc", {code = 200, body = ".*You said Hello!.*"})

            tester:click("/Arc")

            -- we can also make sure that this handler exited, or
            -- in this case didn't since it's a permanent loop
            assert_false(tester:exited())
        end)
    end)
end)
</pre>



Restarting Tir
--------------

Because Tir has a different concept of state it can't reliably or easily do the
"reload on every request" actions.  Instead, reloads will reload your templates,
but your handlers keep running.  To kick your handlers over, just CTRL-C the
Tir app and it will restart everything for you very fast.

It also runs your tests again, because you should write some tests.

Stopping Tir
------------

To make the application quit, use the CTRL-\ (backslash) to send it a TERM
and it will exit gracefully.


How It Works
------------

The *arc_challenge* example is only demonstrating one kind of 
handler you can write, the "natural" kind.  These handlers use coroutines
so that you can "pause" execution in the middle of the handler and wait
for the next request.  This gives you a nice natural way of writing
process oriented code.

If you open the file *app/arc_challenge.lua* you can see the code
for the '/arc' route, which should look like this:

<pre>
require 'tir/engine'

local prompt_page = Tir.view("index.html")
local link_page = Tir.view("link.html")
local reply_page = Tir.view("response.html")

local prompt_form = Tir.form {'msg'}

local function arc(web, req)
    local params = {}

    repeat
        params = web:prompt(prompt_page {form = params})
    until prompt_form:valid(params)

    web:page(link_page {})
    web:click()

    web:page(reply_page {form=params})
end


Tir.start {route = '/Arc', main=arc}
</pre>

What this code does is setup all the pages it needs and a form to
handle input.  The "form" is really just a simple object that
lets you parse and check form submissions and isn't needed to
handle input.  It's just nice to have.

After this you've got the *arc* function which does the real work.
If you skip to the bottom you can see you pass that as the *main=arc*
parameter to *Tir.start*.  This function will get run and "pickled"
for every request that comes in.

Next up, look at the contents of the *arc* function and you'll
see it loosk fairly normal except for the *repeat/until* and
the use of *web:prompt* and *web:click*.  These functions
are part of the web object you get, and they basically tell Tir,
"Pause this function here until the user sends me something new."
In the case of *web:prompt* it sends a page then waits for
a reply of anything.  For *web:click* it pauses until there's
a GET request so you can continue on.

The last thing to look at is the *repeat/until*.  Notice
how all this code does is keep showing the input page until they
get it right.  Since Tir is pausing on each *web:prompt* call
the code does pretty much what you think: show the user a page, get
the form, if it's not valid, repeat.


How Mongrel2 Fits In
--------------------

The last thing to learn about is how Mongrel2 gets configured
to make this work.  If you open *conf/mongrel2.conf* you
see this:


<pre>
arc = Handler(send_spec='tcp://127.0.0.1:9990',
                send_ident='e884a439-31be-4f74-8050-a93565795b25',
                recv_spec='tcp://127.0.0.1:9989', recv_ident='')

main = Server(
    uuid="505417b8-1de4-454f-98b6-07eb9225cca1"
    access_log="/logs/access.log"
    error_log="/logs/error.log"
    chroot="./"
    pid_file="/run/mongrel2.pid"
    default_host="(.+)"
    name="main"
    port=6767
    hosts=[ Host(name="(.+)", routes={ '/Arc': arc }) ]
)

settings = {"zeromq.threads": 1}

servers = [main]
</pre>

This is a fairly vanilla Mongrel2 configuration that just points any
'/arc' requests at the arc handler.

More Than One Handler
---------------------

How you add more than one handler is you just add it to the Mongrel2
configuration as a new route pointed at a new *Handler*.  This means
you will have one Handler for each big route you're dealing with, and
one process for each route using <a href="http://zeromq.org">ZeroMQ</a> 
to talk to Mongrel2.

Alright, so how does the *tir start* command figure this all out?

In your code you have this line:

<pre>
Tir.start {route = '/Arc', main=arc}
</pre>

That one line actually opens up the *conf/config.sqlite* Mongrel2 
configuration and *finds* the Handler you've configured for you.
You don't need to tell Tir information it can get out of the config
database already.

This means, when you run *tir start* you have this final
picture of what's going on:

  #  All of the "app/*.lua" files are started as child processes of *tir*.
  #  Each of those files run like normal, and when Tir.start calls begin serving.
  #  Tir.start looks in the conf/config.sqlite to find the Handler config it should use based on the route you gave it.
  #  Using this config, it sets up the ZeroMQ handler it needs to receive requests.


Changing Tir's Config
---------------------

The last thing to look at is the *conf/config.lua* file, which houses the
basic configuration for most Tir apps:

<pre>
sender_id = '38f857b8-cbaa-4b58-9271-0d36c27813c4'
io_threads = 1
views = "views/"
config_db = 'conf/config.sqlite'
</pre>

These are merged into the options you pass to Tir.start (and Tir.stateless, Tir.evented)
so you can add other options, or override them in certain handlers.  Basically
the options passed to Tir.start override what's in *conf/config.lua*.


Where Views Live
----------------

In the above sample code we had:

<pre>
local prompt_page = Tir.view("index.html")
local link_page = Tir.view("link.html")
local reply_page = Tir.view("response.html")
</pre>

Each of these are loaded out of the *views/* directory and they are "compiled",
meaning they get turned into a template generating lua function.

If you look at *conf/config.lua* again you can see that you can change this
location, and that means you can pass views="BLAH" to Tir.start to change it
again.

PROD Mode
=========

There's not a lot of real deployment gear working yet, but one thing that's supported
is "PROD Mode".  Normally Tir runs in a way that's handy for developers.  In PROD
mode, you set a PROD=1 environ variable and then Tir will not run tests and will
compile templates once.  In normal mode Tir runs your unit tests each time you
kick it over, and templates reload themselves on each request.

To run Tir in PROD mode just do:

<pre>
PROD=1 tir start
</pre>

Deployment
==========

Finally, there's not much for deployment.  I run my apps in <a href="http://www.gnu.org/software/screen/">GNU screen</a> and that's about it.  I'll be doing something better soon.

