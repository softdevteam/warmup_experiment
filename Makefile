PYTHON ?= python2.7
HERE != pwd

all: build-vms build-benchmarks build-benchs bench

.PHONY: build-vms build-benchs bench

build-vms:
	./build.sh

build-benchs:
	cd benchmarks && \
		${MAKE} JAVAC=${HERE}/work/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac

JAVA_HOME =	${HERE}/work/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image
build-krun:
	if ! [ -d krun ]; then \
		git clone https://github.com/softdevteam/krun.git; \
	fi
	cd krun && make JAVA_CPPFLAGS='"-I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux"' JAVA_LDFLAGS=-L${JAVA_HOME}/lib JAVA_CFLAGS=-DWITH_JAVA=1

bench: build-krun build-benchs
	if ! [ -d libkalibera ]; then \
		git clone https://github.com/softdevteam/libkalibera.git; \
	fi
	${PYTHON} krun/krun.py warmup.krun

# XXX target to format results.
