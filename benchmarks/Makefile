HERE !=		pwd
JAVAC ?=	javac

BENCHMARKS = 		binarytrees \
			richards
all:
	for i in ${BENCHMARKS}; do \
		echo "Building java benchmark $${i}..."; \
		cd ${HERE}/$${i}/java && ${JAVAC} *.java; \
		done
