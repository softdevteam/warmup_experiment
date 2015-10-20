PYTHON ?= python2.7
PWD != pwd
JAVA_HOME = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image
JAVAC = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac

# XXX build our on GCC and plug in
CC = cc

all: build-vms build-benchs bench

.PHONY: build-vms build-benchs bench

build-vms:
	./build.sh

build-benchs:
	cd benchmarks && \
		${MAKE} CC=${CC} JAVAC=${JAVAC}

build-krun:
	cd krun && ${MAKE} JAVA_CPPFLAGS='"-I${JAVA_HOME}/include \
		-I${JAVA_HOME}/include/linux"' \
		JAVA_LDFLAGS=-L${JAVA_HOME}/lib \
		JAVAC=${JAVAC} ENABLE_JAVA=1

bench: build-krun build-benchs
	${PYTHON} krun/krun.py warmup.krun

export-graphs:
	${PYTHON} export_all_graphs.py

# XXX target to format results.
