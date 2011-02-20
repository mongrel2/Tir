package = "tir"
version = "{{ VERSION }}"

source = { }

source.url = "http://tir.mongrel2.org/downloads/tir-{{ VERSION }}.tar.gz"
{% if #MD5 > 0 then %}
source.md5 = "{{ MD5 }}"
{% end %}

description = {
   summary = "Tir Mongrel2/Lua Web Framework",
   detailed = "Tir is a framework for doing Web applications in Lua with the Mongrel2 web server.",
   homepage = "http://tir.mongrel2.org",
   license = "BSD",
   maintainer = "zedshaw@zedshaw.com",
}

dependencies = {
   "lua >= 5.1",
   "luaposix == 5.1.2",
    "md5",
    "luajson",
    "lsqlite3",
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

