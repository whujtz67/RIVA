idea:
	mill -i mill.idea.GenIdea/idea

init:
	git submodule update --init
	cd chisel_deps/rocket-chip/dependencies && git submodule update --init cde hardfloat diplomacy chisel

comp:
	mill -i VLSU.compile
	mill -i VLSU.test.compile

test-qh-ring:
	rm -rf build/*
	mkdir build/rtl
	mill -i VLSU.test.runMain test.QhTestTop_Ring -td build | tee ./build/build.log

test-cube:
	rm -rf build/rtl
	mill -i VLSU.test.runMain test.TestTop_Cube -td build | tee ./build/build.log

test-qh-rm:
	rm -rf build/*
	mkdir build/rtl
	mill -i VLSU.test.runMain test.TestTop_RM -td build | tee ./build/build.log
