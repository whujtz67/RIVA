idea:
	mill -i mill.idea.GenIdea/idea

init:
	git submodule update --init
	cd chisel_deps/rocket-chip/dependencies && git submodule update --init cde hardfloat diplomacy chisel

comp:
	mill -i VLSU.compile
	mill -i VLSU.test.compile

test-vlsu:
	rm -rf build/*
	mkdir build/rtl
	mill -i VLSU.test.runMain test.TestVLSU -td build | tee ./build/build.log