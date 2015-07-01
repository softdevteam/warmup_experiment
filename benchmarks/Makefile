HERE !=		pwd
JAVAC ?=	javac

BENCHMARKS = 		binarytrees \
			richards \
			spectralnorm \
			nbody \
			fasta \
			fannkuch_redux
all:
	for i in ${BENCHMARKS}; do \
		echo "Building java benchmark $${i}..."; \
		cd ${HERE}/$${i}/java && \
		CLASSPATH=../../../krun/iterations_runners/ ${JAVAC} *.java; \
		done
