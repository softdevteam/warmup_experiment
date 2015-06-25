PYTHON ?= python2.7
HERE != pwd

all: build-vms build-benchmarks build-benchs bench

.PHONY: build-vms build-benchs bench

build-vms:
	./build.sh

build-benchs:
	cd benchmarks && \
		${MAKE} JAVAC=${HERE}/work/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac

bench: build-benchs
	if ! [ -d krun ]; then \
		git clone https://github.com/softdevteam/krun.git && \
		cd krun && make; \
	fi
	if ! [ -d libkalibera ]; then \
		git clone https://github.com/softdevteam/libkalibera.git; \
	fi
	env LD_LIBRARY_PATH=${HERE}/krun/libkruntime ${PYTHON} krun/krun.py warmup.krun

# XXX target to format results.
