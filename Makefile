PYTHON ?= python2.7
PWD != pwd
UNAME != uname
WINDOW_SIZE ?= 200
STEADY_STATE_EXPECTED ?= 500
OUTLIER_THRESHOLD ?= 8
PLOTS_NO_CPTS = plots_w${WINDOW_SIZE}.pdf
PLOTS_WITH_CPTS = plots_w${WINDOW_SIZE}_changepoints.pdf
ifeq (${UNAME}, Linux)
	JAVA_HOME = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image
	JAVAC = ${PWD}/work/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac
	JAVA_INC = ${JAVA_HOME}/include/linux
	GCC_LIB_DIR = ${PWD}/work/gcc-inst/lib64
endif
ifeq (${UNAME}, OpenBSD)
	JAVA_HOME = ${PWD}/work/openjdk/build/bsd-x86_64-normal-server-release/images/j2sdk-image
	JAVAC = ${PWD}/work/openjdk/build/bsd-x86_64-normal-server-release/jdk/bin/javac
	JAVA_INC = ${JAVA_HOME}/include/openbsd
	GCC_LIB_DIR = ${PWD}/work/gcc-inst/lib
endif
LIBKRUN_DIR=${PWD}/krun/libkrun

CC=${PWD}/work/gcc-inst/bin/zgcc
R_LD_LIBRARY_PATH=${PWD}/work/R-inst/lib/R/lib

all: build-benchmarks build-startup
	@echo ""
	@echo "============================================================"
	@echo "Now run 'make bench-no-reboots' or 'make bench-with-reboots'"
	@echo "If you want reboots, make sure you set up the init system!"
	@echo "============================================================"

.PHONY: build-vms build-benchmarks build-krun build-startup bench clean
.PHONY: plot-warmup-results plot-warmup-outliers-by-threshold
.PHONY: plot-dacapo-results plot-octane-results
.PHONY: clean-benchmarks clean-krun clean-plots

build-vms:
	./build.sh

build-benchmarks: build-krun
	cd benchmarks && \
		env LD_LIBRARY_PATH=${GCC_LIB_DIR} \
		CC=${CC} JAVAC=${JAVAC} ${MAKE}

build-krun: build-vms
	cd krun && env LD_LIBRARY_PATH=${GCC_LIB_DIR} CC=${CC} \
		JAVA_CPPFLAGS='"-I${JAVA_HOME}/include -I${JAVA_INC}"' \
		JAVA_LDFLAGS=-L${JAVA_HOME}/lib \
		JAVAC=${JAVAC} ENABLE_JAVA=1 ${MAKE}

build-startup: build-krun
	cd startup_runners && \
		env LD_LIBRARY_PATH=${GCC_LIB_DIR} CC=${CC} \
		JAVA_CPPFLAGS='"-I${JAVA_HOME}/include \
		-I${JAVA_HOME}/include/linux"' \
		JAVA_LDFLAGS=-L${JAVA_HOME}/lib \
		JAVAC=${JAVAC} ENABLE_JAVA=1 ${MAKE}

bench-no-reboots: build-krun build-benchmarks
	${PYTHON} krun/krun.py warmup.krun

bench-with-reboots: build-krun build-benchmarks
	${PYTHON} krun/krun.py --hardware-reboots warmup.krun

bench-startup-no-reboots: build-startup build-benchmarks
	${PYTHON} krun/krun.py startup.krun

bench-startup-with-reboots: build-startup build-benchmarks
	${PYTHON} krun/krun.py --hardware-reboots startup.krun

bench-dacapo: build-krun build-vms
	PYTHONPATH=krun/ JAVA_HOME=${JAVA_HOME} LD_LIBRARY_PATH=${GCC_LIB_DIR} ${PYTHON} extbench/rundacapo.py

bench-octane: build-krun build-vms
	PYTHONPATH=krun/ LD_LIBRARY_PATH=${GCC_LIB_DIR}:${LIBKRUN_DIR} ${PYTHON} extbench/runoctane.py

plot-warmup-results:
	bin/mark_outliers_in_json -w ${WINDOW_SIZE} -t ${OUTLIER_THRESHOLD} warmup_results.json.bz2
	bin/mark_changepoints_in_json -s ${STEADY_STATE_EXPECTED} warmup_results_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results -w ${WINDOW_SIZE} -m -t --with-outliers -o warmup_${PLOTS_NO_CPTS} warmup_results_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results -w ${WINDOW_SIZE} -m -t --with-outliers --with-changepoints -o warmup_${PLOTS_WITH_CPTS} warmup_results_outliers_w${WINDOW_SIZE}_changepoints.json.bz2

plot-warmup-outliers-by-threshold:
	bin/calculate_outliers_by_threshold warmup_results.json.bz2
	mv outliers_per_threshold.json.bz2 warmup_outliers_per_threshold.json.bz2
	bin/plot_outliers_per_threshold warmup_outliers_per_threshold.json.bz2

# The following plotting targets assume that build_stats.sh has been used to
# install the necessary R and Python environment under 'work/'.

# Note: Graal is skipped on OpenBSD
plot-dacapo-results:
	bin/csv_to_krun_json -u "`uname -a`" -v HotSpot -l Java dacapo.hotspot.results
	bin/mark_outliers_in_json -w ${WINDOW_SIZE} -t ${OUTLIER_THRESHOLD} dacapo.hotspot.json.bz2
	LD_LIBRARY_PATH=${R_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH} bin/mark_changepoints_in_json -s ${STEADY_STATE_EXPECTED} dacapo.hotspot_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers -o dacapo.hotspot_${PLOTS_NO_CPTS} dacapo.hotspot_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers --with-changepoints -o dacapo.hotspot_${PLOTS_WITH_CPTS} dacapo.hotspot_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	if [ -e dacapo.graal.results ]; then \
		bin/csv_to_krun_json -u "`uname -a`" -v Graal -l Java dacapo.graal.results && \
		bin/mark_outliers_in_json -w ${WINDOW_SIZE} -t ${OUTLIER_THRESHOLD} dacapo.graal.json.bz2 && \
		LD_LIBRARY_PATH=${R_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH} bin/mark_changepoints_in_json -s ${STEADY_STATE_EXPECTED} dacapo.graal_outliers_w${WINDOW_SIZE}.json.bz2 && \
		bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers -o dacapo.graal_${PLOTS_NO_CPTS} dacapo.graal_outliers_w${WINDOW_SIZE}.json.bz2 && \
		bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers --with-changepoints -o dacapo.graal_${PLOTS_WITH_CPTS} dacapo.graal_outliers_w${WINDOW_SIZE}_changepoints.json.bz2; \
		fi

# Note: Spidermonkey is skipped on OpenBSD
plot-octane-results:
	bin/csv_to_krun_json -u "`uname -a`" -v V8 -l JavaScript octane.v8.results
	bin/mark_outliers_in_json -w ${WINDOW_SIZE} -t ${OUTLIER_THRESHOLD} octane.v8.json.bz2
	LD_LIBRARY_PATH=${R_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH} bin/mark_changepoints_in_json -s ${STEADY_STATE_EXPECTED} octane.v8_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers -o octane.v8_${PLOTS_NO_CPTS} octane.v8_outliers_w${WINDOW_SIZE}.json.bz2
	bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers --with-changepoints -o octane.v8_${PLOTS_WITH_CPTS} octane.v8_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	if [ -e octane.spidermonkey.results ]; then \
		bin/csv_to_krun_json -u "`uname -a`" -v SpiderMonkey -l JavaScript octane.spidermonkey.results && \
		bin/mark_outliers_in_json -w ${WINDOW_SIZE} -t ${OUTLIER_THRESHOLD} octane.spidermonkey.json.bz2 && \
		LD_LIBRARY_PATH=${R_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH} bin/mark_changepoints_in_json -s ${STEADY_STATE_EXPECTED} octane.spidermonkey_outliers_w${WINDOW_SIZE}.json.bz2 && \
		bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers -o octane.spidermonkey_${PLOTS_NO_CPTS} octane.spidermonkey_outliers_w${WINDOW_SIZE}.json.bz2 && \
		bin/plot_krun_results --wallclock-only -w ${WINDOW_SIZE} -m -t --with-outliers --with-changepoints -o octane.spidermonkey_${PLOTS_WITH_CPTS} octane.spidermonkey_outliers_w${WINDOW_SIZE}_changepoints.json.bz2; \
		fi

tables-warmup:
	bin/table_classification_summaries_main -o bencher3.table warmup_results_0_7_linux1_i7_4790k_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	bin/table_classification_summaries_main -o bencher5.table warmup_results_0_7_linux2_i7_4790_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	bin/table_classification_summaries_main -o bencher6.table warmup_results_0_7_openbsd1_i7_4790_outliers_w${WINDOW_SIZE}_changepoints.json.bz2

tables-dacapo-results:
	bin/table_classification_summaries_others -s 2 -o dacapo.table dacapo.graal_outliers_w${WINDOW_SIZE}_changepoints.json.bz2 dacapo.hotspot_outliers_w${WINDOW_SIZE}_changepoints.json.bz2

tables-octane-results:
	bin/table_classification_summaries_others -s 2 -o octane.table octane.spidermonkey_outliers_w${WINDOW_SIZE}.json.bz2 octane.v8_outliers_w${WINDOW_SIZE}.json.bz2

clean: clean-benchmarks clean-krun clean-plots
	rm -rf work

clean-benchmarks:
	cd benchmarks && ${MAKE} clean
	rm -rf extbench/octane/dacapo*.jar extbench/octane

clean-krun:
	cd krun && ${MAKE} clean

clean-plots:
	rm -f warmup_*.pdf
	rm -f warmup_outliers_per_threshold.json.bz2
	rm -f warmup_results_outliers_w${WINDOW_SIZE}.json.bz2 warmup_results_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	rm -f octane.v8_*.pdf octane.spidermonkey_*.pdf
	rm -f octane.v8_outliers_w${WINDOW_SIZE}.json.bz2 octane.v8_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	rm -f octane.spidermonkey_outliers_w${WINDOW_SIZE}.json.bz2 octane.spidermonkey_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	rm -f dacapo_*.pdf
	rm -f dacapo.graal_outliers_w${WINDOW_SIZE}.json.bz2 dacapo.graal_outliers_w${WINDOW_SIZE}_changepoints.json.bz2
	rm -f dacapo.hotspot_outliers_w${WINDOW_SIZE}.json.bz2 dacapo.hotspot_outliers_w${WINDOW_SIZE}_changepoints.json.bz2

clean-tables:
	rm -f bencher*.table dacapo.table octane.table
