VERSION=0.1-1


install:
	luarocks install lua_signal
	curl -O https://github.com/iamaleksey/lua-zmq/raw/master/rockspecs/lua-zmq-scm-0.rockspec
	luarocks install lua-zmq-scm-0.rockspec
	curl -O https://github.com/jsimmons/mongrel2-lua/raw/master/rockspecs/mongrel2-lua-scm-0.rockspec
	luarocks install mongrel2-lua-scm-0.rockspec
	luarocks install http://mongrel2.org/static/tir-${VERSION}.rockspec

dist:
	rm -rf tmp
	mkdir tmp
	
