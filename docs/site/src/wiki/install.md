Installing Tir
==============

This document is still a rough install guide, so you may have to wiggle the instructions to fit your particular system.  They also do *not* work on Windows.  Don't even bother.

Pre-Requisites
==============

Obviously, you'll need to <a href="http://mongrel2.org/wiki/quick_start.html">Install Mongrel2</a> first.

You'll also need the following:

1. <a href="http://lua.org">Lua 5.1</a>
2. <a href="http://luarocks.org/">LuaRocks</a>
3. Make sure you can build extensions for Lua.

Installing Tir
=========

Because of the way a LuaRocks handles some types of dependencies you have to run these commands to get Tir installed the first time:

<pre>
# go some place safe
cd /tmp

# become root (watch out!)
sudo bash

# install dependencies from git and places
luarocks install lua_signal
curl -OL https://github.com/iamaleksey/lua-zmq/raw/master/rockspecs/lua-zmq-scm-0.rockspec
luarocks install lua-zmq-scm-0.rockspec
curl -OL https://github.com/jsimmons/mongrel2-lua/raw/master/rockspecs/mongrel2-lua-1.6.1.rockspec
luarocks install mongrel2-lua-1.6.1.rockspec

# install tir
luarocks install http://tir.mongrel2.org/downloads/tir-0.9.3-3.rockspec

# stop being root
exit
</pre>

*NOTE:* This set of instructions should be one single command that just installs the Tir rockspec.  If you know how to make that happen let me know.


Testing
=========

After that you should be able to do this:

<pre>
$ tir
ERROR: that's not a valid command
USAGE: tir <command> <options>
$ tir help
AVAILABLE COMMANDS:
test
help
start
</pre>

More Documentation
=========

After you have Tir installed you probably want to read the [Quick Start](/wiki/quick_start.html) document.

If you want to work on Tir then read the [Contributor Instructions](/wiki/contributing.html) document.


