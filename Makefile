VERSION=0.9.3
REVISION=3
SPEC_FILE=tir-${VERSION}-${REVISION}.rockspec
TAR_FILE=tir-${VERSION}-${REVISION}.tar.gz
SRC_ROCK=tir-${VERSION}-${REVISION}.src.rock
EXAMPLES_FILE=tir-examples-${VERSION}-${REVISION}.tar.gz

all:
	m2sh load -db tests/data/config.sqlite -config tests/data/mongrel2.conf
	tir test

install:
	luarocks install lua_signal
	curl -O https://raw.github.com/jsimmons/tnetstrings.lua/master/rockspecs/tnetstrings-scm-0.rockspec
	luarocks install tnetstrings-scm-0.rockspec
	rm tnetstrings-scm-0.rockspec
	curl -O https://raw.github.com/jsimmons/mongrel2-lua/master/rockspecs/mongrel2-lua-scm-0.rockspec
	luarocks install mongrel2-lua-scm-0.rockspec
	rm mongrel2-lua-scm-0.rockspec
	luarocks install rockspec/tir-scm-0.rockspec

build:
	rm -rf tmp
	mkdir tmp
	git archive -o tmp/tir-${VERSION}.zip --prefix tir-${VERSION}/ HEAD
	cd tmp && unzip tir-${VERSION}.zip && mv tir-${VERSION} tir-${VERSION}-${REVISION} && tar -czf ${TAR_FILE} tir-${VERSION}-${REVISION}
	cd tmp/tir-${VERSION}-${REVISION} && tar -czf ../${EXAMPLES_FILE} examples
	lua tools/specgen.lua ${VERSION}-${REVISION} tmp/${SPEC_FILE} tmp/${TAR_FILE}

dist: build
	rsync -azv tmp/${TAR_FILE} tmp/${SPEC_FILE} tmp/${EXAMPLES_FILE} ${USER}@tir.mongrel2.org:/var/www/tir.mongrel2.org/downloads/
	cd tmp && luarocks pack tir-${VERSION}-${REVISION}.rockspec
	rsync -azv tmp/${SRC_ROCK} ${USER}@tir.mongrel2.org:/var/www/tir.mongrel2.org/downloads/

clean:
	rm -rf tmp

