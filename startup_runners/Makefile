PWD != pwd
C_ITER_RUNNER_CFLAGS = -fPIC -Wall -Wextra -pedantic
C_ITER_RUNNER_LDFLAGS =


OS != uname -s
ifeq ($(OS),Linux)
	C_ITER_RUNNER_LDFLAGS += -ldl
endif

.PHONY: clean

all: outer_startup_runner_c startup_runner_c startup_runner.class

startup_runner.class: startup_runner.java
	if [ "${ENABLE_JAVA}" = "1" ]; then \
		CLASSPATH=../krun/iterations_runners/ ${JAVAC} startup_runner.java; \
	fi


outer_startup_runner_c: outer_startup_runner.c
	${CC} --std=c99 ${C_ITER_RUNNER_CFLAGS} ${CFLAGS} -L${PWD}/../krun/libkrun \
		${CPPFLAGS} outer_startup_runner.c -I${PWD}/../krun/libkrun \
		-o outer_startup_runner_c -lkruntime ${C_ITER_RUNNER_LDFLAGS} \
		${LDFLAGS}

startup_runner_c: startup_runner.c
	${CC} --std=c99 ${C_ITER_RUNNER_CFLAGS} ${CFLAGS} -L${PWD}/../krun/libkrun \
		${CPPFLAGS} startup_runner.c -I${PWD}/../krun/libkrun \
		-o startup_runner_c -lkruntime ${C_ITER_RUNNER_LDFLAGS} \
		${LDFLAGS}

clean:
	rm -f startup_runner_c outer_startup_runner_c startup_runner.class
