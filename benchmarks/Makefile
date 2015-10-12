PWD !=		pwd

# We build the C benchmarks as a shared object, which we will then dlopen()
BENCH_CFLAGS =	-shared -Wall -fPIC -m64

BENCHMARKS = 		binarytrees \
			richards \
			spectralnorm \
			nbody \
			fasta \
			fannkuch_redux

# XXX Once all complete, will disappear
C_BENCHMARKS = richards

all: java-benchmarks c-benchmarks

java-benchmarks:
	for i in ${BENCHMARKS}; do \
		echo "Building java benchmark $${i}..."; \
		cd ${PWD}/$${i}/java && \
		CLASSPATH=../../../krun/iterations_runners/ ${JAVAC} *.java; \
		done

c-benchmarks:
	for i in ${C_BENCHMARKS}; do \
		echo "Building C benchmark $${i}..."; \
		cd ${PWD}/$${i}/c && \
		${CC} ${CFLAGS} ${CPPFLAGS} ${BENCH_CFLAGS} -o bench.so bench.c || exit $?; \
		done
