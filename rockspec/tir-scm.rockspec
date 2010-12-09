package = "tir"
version = "scm"

source = { }
source.url = "http://tir.mongrel2.org/downloads/tir-scm.tar.gz"

description = {
   summary = "Tir Mongrel2/Lua Web Framework",
   detailed = "Tir is a framework for doing Web applications in Lua with the Mongrel2 web server.",
   homepage = "http://tir.mongrel2.org",
   license = "BSD",
   maintainer = "zedshaw@zedshaw.com",
}
dependencies = {
   "lua >= 5.1",
    "md5",
    "luajson",
    "luasql-sqlite3",
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
            ['tir.error'] = 'tir/error.lua',
            ['tir.form'] = 'tir/form.lua',
            ['tir.m2'] = 'tir/m2.lua',
            ['tir.session'] = 'tir/session.lua',
            ['tir.strict'] = 'tir/strict.lua',
            ['tir.task'] = 'tir/task.lua',
            ['tir.util'] = 'tir/util.lua',
            ['tir.view'] = 'tir/view.lua',
            ['tir.web'] = 'tir/web.lua',
            ['tir.strict'] = 'tir/strict.lua',
        }
    }
}
