PYTHON ?= python2.7
PWD != pwd
UNAME != uname
ifeq (${UNAME}, Linux)
	JAVA_HOME = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image
	JAVAC = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac
	JAVA_INC = ${JAVA_HOME}/include/linux
endif
ifeq (${UNAME}, OpenBSD)
	JAVA_HOME = ${PWD}/work/openjdk/build/bsd-x86_64-normal-server-release/images/j2sdk-image
	JAVAC = ${PWD}/work/openjdk/build/bsd-x86_64-normal-server-release/jdk/bin/javac
	JAVA_INC = ${JAVA_HOME}/include/openbsd
endif

# XXX build our on GCC and plug in
CC = cc

all: build-vms build-benchs build-krun build-startup bench

.PHONY: build-vms build-benchs build-krun build-startup bench

build-vms:
	./build.sh

build-benchs: build-krun
	cd benchmarks && \
		${MAKE} CC=${CC} JAVAC=${JAVAC}

build-krun:
	cd krun && ${MAKE} JAVA_CPPFLAGS='"-I${JAVA_HOME}/include -I${JAVA_INC}"' \
		JAVA_LDFLAGS=-L${JAVA_HOME}/lib \
		JAVAC=${JAVAC} ENABLE_JAVA=1

build-startup: build-krun
	cd startup_runners && ${MAKE} JAVA_CPPFLAGS='"-I${JAVA_HOME}/include \
		-I${JAVA_HOME}/include/linux"' \
		JAVA_LDFLAGS=-L${JAVA_HOME}/lib \
		JAVAC=${JAVAC} ENABLE_JAVA=1

bench: build-krun build-benchs
	${PYTHON} krun/krun.py warmup.krun

export-graphs:
	${PYTHON} export_all_graphs.py

# XXX target to format results.
