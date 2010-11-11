package = "tir"
version = "0.1-1"

source = {
   url = "http://mongrel2.org/static/tir-0.1.tar.gz",
   md5 = "887e49ea6fc23133ab719e4a9572ff79",
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
            ['tir.engine'] = 'tir/engine.lua',
            ['tir.strict'] = 'tir/strict.lua',
        }
    }
}

