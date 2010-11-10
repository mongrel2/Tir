VERSION=0.1
REVISION=1


install:
	luarocks install lua_signal
	curl -O https://github.com/iamaleksey/lua-zmq/raw/master/rockspecs/lua-zmq-scm-0.rockspec
	luarocks install lua-zmq-scm-0.rockspec
	curl -O https://github.com/jsimmons/mongrel2-lua/raw/master/rockspecs/mongrel2-lua-scm-0.rockspec
	luarocks install mongrel2-lua-scm-0.rockspec
	luarocks install http://mongrel2.org/static/tir-${VERSION}-${REVISION}.rockspec

dist_build:
	rm -rf tmp
	mkdir tmp
	fossil zip trunk tmp/tir-${VERSION}.zip --name tir-${VERSION}
	cd tmp && unzip tir-${VERSION}.zip && tar -czvf tir-${VERSION}.tar.gz tir-${VERSION}
	cp rockspec/*.rockspec tmp
	md5sum tmp/tir-${VERSION}.tar.gz 

dist:
	rsync -azv tmp/tir-${VERSION}.tar.gz tmp/tir-${VERSION}-${REVISION}.rockspec ${USER}@mongrel2.org:deployment/files/static

	cd tmp && luarocks pack tir-${VERSION}-${REVISION}.rockspec
	rsync -azv tmp/tir-${VERSION}-${REVISION}.src.rock ${USER}@mongrel2.org:deployment/files/static/


