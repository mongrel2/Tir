package = "tir"
version = "0.1-1"

source = {
   url = "http://mongrel2.org/static/tir-0.1.tar.gz",
   md5 = "281a6bbbed58274de8742e30c2b1ecf5",
}

description = {
   summary = "Tir Mongrel2/Lua Web Framework",
   detailed = [[
       Tir is a framework for doing Web applications in
       Lua with the Mongrel2 web server.
   ]],
   homepage = "http://tir.mongrel2.org",
   license = "BSD",
   maintainer = "zedshaw@zedshaw.com",
}

dependencies = {
   "lua >= 5.1",
    "md5",
    "luuid",
    "luajson",
    -- these are more advisory than anything
    "http://luarocks.org/repositories/rocks/lua_signal-20100412-1.rockspec",
    "https://github.com/jsimmons/mongrel2-lua/raw/master/rockspecs/mongrel2-lua-scm-0.rockspec",
    "luasql-sqlite3",
    "luaposix",
    "telescope",
}

build = {
    type = "none",
    install = {
        bin = {
            'bin/tir',
        },

        lua = {
            Tir = 'tir/engine.lua',
            strict = 'tir/strict.lua',
        }
    }
}

