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


Tir.start {route = '/arc', main=arc}

