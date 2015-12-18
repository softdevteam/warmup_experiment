# GNU Make!
PHONY: java-benchmarks c-benchmarks clean-java-benchmarks clean-c-benchmarks clean

PWD !=		pwd

# We build the C benchmarks as a shared object, which we will then dlopen()
BENCH_CFLAGS =	-shared -Wall -fPIC -m64

BENCHMARKS = 		binarytrees \
			richards \
			spectralnorm \
			nbody \
			fasta \
			fannkuch_redux

# Extra linker flags for C benchmarks
C_EXTRA_LDFLAGS_binarytrees = -lm
C_EXTRA_LDFLAGS_nbody = -lm
C_EXTRA_LDFLAGS_spectralnorm = -lm

all: java-benchmarks c-benchmarks

java-benchmarks:
	for i in ${BENCHMARKS}; do \
		echo "Building java benchmark $${i}..."; \
		cd ${PWD}/$${i}/java && \
		CLASSPATH=../../../krun/iterations_runners/ ${JAVAC} *.java; \
		done

c-benchmarks:
	$(foreach i, ${BENCHMARKS}, \
		echo "Building C benchmark ${i}..."; \
		cd ${PWD}/${i}/c && \
		${CC} ${CFLAGS} ${CPPFLAGS} ${C_EXTRA_LDFLAGS_${i}} \
		${BENCH_CFLAGS} -o bench.so bench.c || exit $?; \
		)

clean: clean-c-benchmarks clean-java-benchmarks

clean-java-benchmarks:
	for i in ${BENCHMARKS}; do \
		cd ${PWD}/$${i}/java && rm -f *.class; \
	done

clean-c-benchmarks:
	for i in ${BENCHMARKS}; do \
		cd ${PWD}/$${i}/c && rm -f bench.so; \
	done
