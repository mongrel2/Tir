VERSION=0.5
REVISION=1
SPEC_FILE=tir-${VERSION}-${REVISION}.rockspec
TAR_FILE=tir-${VERSION}-${REVISION}.tar.gz
SRC_ROCK=tir-${VERSION}-${REVISION}.src.rock
EXAMPLES_FILE=tir-examples-${VERSION}-${REVISION}.tar.gz

install:
	luarocks install lua_signal
	curl -O https://github.com/iamaleksey/lua-zmq/raw/master/rockspecs/lua-zmq-scm-0.rockspec
	luarocks install lua-zmq-scm-0.rockspec
	curl -O https://github.com/jsimmons/mongrel2-lua/raw/master/rockspecs/mongrel2-lua-scm-0.rockspec
	luarocks install mongrel2-lua-scm-0.rockspec
	luarocks install http://tir.mongrel2.org/downloads/tir-${VERSION}-${REVISION}.rockspec

build:
	rm -rf tmp
	mkdir tmp
	fossil zip trunk tmp/tir-${VERSION}.zip --name tir-${VERSION}
	cd tmp && unzip tir-${VERSION}.zip && mv tir-${VERSION} tir-${VERSION}-${REVISION} && tar -czf ${TAR_FILE} tir-${VERSION}-${REVISION}
	cd tmp/tir-${VERSION}-${REVISION} && tar -czf ../${EXAMPLES_FILE} examples
	lua tools/specgen.lua ${VERSION}-${REVISION} tmp/${SPEC_FILE} tmp/${TAR_FILE}
	lua tools/specgen.lua scm rockspec/tir-scm.rockspec

dist: build
	rsync -azv tmp/${TAR_FILE} tmp/${SPEC_FILE} tmp/${EXAMPLES_FILE} ${USER}@mongrel2.org:deployment/files/tir/downloads/
	cd tmp && luarocks pack tir-${VERSION}-${REVISION}.rockspec
	rsync -azv tmp/${SRC_ROCK} ${USER}@mongrel2.org:deployment/files/tir/downloads/

clean:
	rm -rf tmp

