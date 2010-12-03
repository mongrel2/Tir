require 'tir/engine'
require 'md5'

local version, target, source_tar = unpack(arg)

local spec = Tir.view('tir-scm.rockspec')
local tar_md5 = ""

if source_tar then
    local tar_file = assert(io.open(source_tar, 'r'))
    tar_md5 = md5.sumhexa(tar_file:read('*a'))
    tar_file:close()
end

local out = io.open(target, 'w')
out:write(spec {VERSION = version, MD5 = tar_md5})
out:close()

print("Wrote to spec file " .. target)

