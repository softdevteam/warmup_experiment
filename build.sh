#! /bin/sh

# This assumes a linux x86_64 machine. We used Debian 8.

missing=0
check_for () {
	which $1 > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: can't find $1 binary"
        missing=1
    fi
}

check_for cc
check_for g++
check_for bunzip2
check_for git
check_for hg
check_for python
check_for svn
check_for unzip
check_for xml2-config
which pypy > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
    PYTHON=`which pypy`
else
    PYTHON=`which python2.7`
fi

# java versions need to be jdk7
# we will build a jdk 8 later.
# graal build needs both of these!
check_for java
check_for javac

which gmake > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
    MYMAKE=gmake
else
    MYMAKE=make
fi
check_for bash

if [ $missing -eq 1 ]; then
    exit 1
fi

HERE=`pwd`
wrkdir=${HERE}/work
PATCH_DIR=${HERE}/patches

mkdir -p ${wrkdir}
echo "===> Working in $wrkdir"

PATCH_DIR=`pwd`/patches/

CPYTHONV=2.7.10
build_cpython() {
	cd ${wrkdir} || exit $?
	echo "\n===> Download and build CPython\n"
	if [ -f ${wrkdir}/cpython/python ]; then return; fi
	cd $wrkdir
	wget http://python.org/ftp/python/${CPYTHONV}/Python-${CPYTHONV}.tgz || exit $?
	tar xfz Python-${CPYTHONV}.tgz || exit $?
	mv Python-${CPYTHONV} cpython
	cd cpython
	./configure || exit $?
	$MYMAKE || exit $?
	#cp $wrkdir/cpython/Lib/test/pystone.py $wrkdir/benchmarks/dhrystone.py
}


LUAJITV=2.0.4
build_luajit() {
	cd ${wrkdir} || exit $?
	echo "\n===> Download and build LuaJIT\n"
	if [ -f ${wrkdir}/luajit/src/luajit ]; then return; fi
	wget http://luajit.org/download/LuaJIT-${LUAJITV}.tar.gz || exit $?
	tar xfz LuaJIT-${LUAJITV}.tar.gz
	mv LuaJIT-${LUAJITV} luajit
	cd luajit
	$MYMAKE || exit $?
}

PYPYV=2.6.0
build_pypy() {
	cd ${wrkdir} || exit $?
	echo "\n===> Download and build PyPy\n"
	if [ -f ${wrkdir}/pypy/pypy/goal/pypy-c ]; then return; fi
	wget https://bitbucket.org/pypy/pypy/downloads/pypy-${PYPYV}-src.tar.bz2 || exit $?
	bunzip2 -c - pypy-${PYPYV}-src.tar.bz2 | tar xf -
	mv pypy-${PYPYV}-src pypy
	cd pypy/pypy/goal/
	usession=`mktemp -d`
	PYPY_USESSION_DIR=$usession $PYTHON ../../rpython/bin/rpython -Ojit || exit $?
	rm -rf $usession
}


V8_V=4.5.38
DEPOT_V=015cdc34ba4be808c47267123b0a97b93f5a0407
DEPOT_REPO="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
build_v8() {
	cd ${wrkdir} || exit $?
	echo "\n===> Download and build V8\n"

	if [ -f ${wrkdir}/v8/out/native/d8 ]; then return; fi

	git clone ${DEPOT_REPO}
	cd depot_tools || exit $?
	git checkout ${DEPOT_V} || exit $?

	# The build actually requires that you clone using this git wrapper tool
	cd ${wrkdir}
	OLDPATH=${PATH}
	PATH=${wrkdir}/depot_tools:${PATH}
	fetch v8 || exit $?
	cd v8 || exit $?
	git checkout ${V8_V} || exit $?
	patch -Ep1 < ${PATCH_DIR}/v8_clock_gettime_monotonic.diff || exit $?
	make native || exit $?
	PATH=${OLDPATH}
}

# There is a bug in the JDK8 build system which makes it incompatible with GNU make 4
# http://stackoverflow.com/questions/21246042/scrambled-arguments-when-building-openjdk
# Let's build 3.82 then.
GMAKE_V=3.82
build_gmake() {
	echo "\n===> Download and build gmake-${GMAKE_V}\n"
	if [ -f ${wrkdir}/make-${GMAKE_V}/make ]; then return; fi
	cd ${wrkdir} || exit $?
	wget http://ftp.gnu.org/gnu/make/make-${GMAKE_V}.tar.gz || exit $?
	tar zxvf make-${GMAKE_V}.tar.gz || exit $?
	cd make-${GMAKE_V} || exit $?
	./configure || exit $?
	make || exit $?
}

JDK_DIST=openjdk-8-src-b132-03_mar_2014.zip
build_jdk() {
	echo "\n===> Download and build JDK8\n"
	if [ -f ${wrkdir}/openjdk/build/linux-x86_64-normal-server-release/jdk/bin/javac ]; then return; fi
	cd ${wrkdir} || exit $?
	if ! [ -f "${wrkdir}/openjdk-8-src-b132-03_mar_2014.zip" ]; then
		wget http://www.java.net/download/openjdk/jdk8/promoted/b132/${JDK_DIST} || exit $?
	fi
	unzip ${JDK_DIST} || exit $?
	cd openjdk || exit $?
	JDK_BUILD_PATH=${wrkdir}/make-${GMAKE_V}:${PATH}
	PATH=${JDK_BUILD_PATH} bash configure || exit $?
	PATH=${JDK_BUILD_PATH} make all || exit $?
}

# XXX read more into the SERVER versions. Are we using the right one?
MX="PATH=${wrkdir}/graal/mxtool:${PATH} EXTRA_JAVA_HOMES=/usr/lib/jvm/java-7-openjdk-amd64 JAVA_HOME=${wrkdir}/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image/ DEFAULT_VM=server mx"
build_graal() {
	echo "\n===> Download and build graal\n"
	if [ -f ${wrkdir}/graal/jdk1.8.0-internal/product/bin/javac ]; then return; fi
	cd ${wrkdir}
	if ! [ -d ${wrkdir}/graal ]; then
		hg clone http://hg.openjdk.java.net/graal/graal || exit $?
	fi
	cd graal
	env ${MX} build
	# '${MX} vm' runs the vm
}


JRUBY_V=b0b724952eaf283ea03fd39517243ac509e5932a
build_jruby_truffle() {
	echo "\n===> Download and build truffle+jruby\n"
	cd ${wrkdir}
	if [ -f ${wrkdir}/jruby/bin/jruby ]; then return; fi
	if ! [ -d ${wrkdir}/jruby ]; then
		git clone https://github.com/jruby/jruby.git || exit $?
	fi
	cd ${wrkdir}/jruby || exit $?
	git checkout ${JRUBY_V} || exit $?
	./mvnw || exit $?
	GRAAL_BIN=${wrkdir}/graal/jdk1.8.0-internal/product/bin/java ${wrkdir}/jruby/bin/jruby ${wrkdir}/jruby/tool/jt.rb build || exit $?

	# http://lafo.ssw.uni-linz.ac.at/graalvm/jruby/doc/
	# to run the vm:
	#JAVACMD=${wrkdir}/graal/jdk1.8.0-internal/product/bin/java ${wrkdir}/jruby/bin/jruby -X+T -J-server ...

	echo "--> Check graal is enabled in JRuby+Truffle"
	graal_en=`JAVACMD=${wrkdir}/graal/jdk1.8.0-internal/product/bin/java ${wrkdir}/jruby/bin/jruby -X+T -J-server -e "puts Truffle.graal?"`
	if ! [ "${graal_en}" = "true" ]; then echo "graal was not enabled!!!" && exit 1; fi
}


kHVM_VERSION=HHVM-3.7.1
build_hhvm() {
	echo "\n===> Download and build HHVM\n"
	if [ -f ${wrkdir}/hhvm/hphp/hhvm/php ]; then return; fi
	cd ${wrkdir} || exit $?
	if ! [ -d ${wrkdir}/hhvm ]; then
		git clone https://github.com/facebook/hhvm.git || exit $?
	fi
	cd hhvm || exit $?
	git checkout ${HHVM_VERSION} || exit $?
	git submodule update --init --recursive || exit $?
	patch -Ep1 < ${PATCH_DIR}/hhvm_clock_gettime_monotonic.diff || exit $?
	patch -Ep1 < ${PATCH_DIR}/hhvm_cmake.diff || exit $?
	sh -c "cmake -DMYSQL_UNIX_SOCK_ADDR=/dev/null -DBOOST_LIBRARYDIR=/usr/lib/x86_64-linux-gnu/ . && make" || exit $?
	# vm is ${wrkdir}/hhvm/hphp/hhvm/php
}


fetch_external_benchmarks() {
	echo "\n===> Download and build misc benchmarks\n"

cat << EOF
In order to build these benchmarks, you need to agree to the licensing terms
of the Java Richards benchmark at:
  http://web.archive.org/web/20050825101121/http://www.sunlabs.com/people/mario/java_benchmarking/index.html
EOF

	echo -n "Have you read and agreed to these terms? [Ny] " || exit $?
	read answer || exit $?
	case "$answer" in
	    y | Y) ;;
	    *) exit 1;;
	esac

	t=`mktemp -d` || exit $?
	cd $t || exit $?
    wget http://www.wolczko.com/richdbsrc.zip || exit $?
	unzip richdbsrc.zip || exit $?
	mv Benchmark.java Program.java COM/sun/labs/kanban/richards_deutsch_acc_virtual/ || exit $?
	cd COM/sun/labs/kanban/richards_deutsch_acc_virtual || exit $?
	mv Richards.java richards.java || exit $?
	patch < ${PATCH_DIR}/java_richards.patch || exit $?
	cp *.java ${HERE}/benchmarks/richards/java || exit $?
	rm -fr $t

	# XXX hook these in later.
	#t=`mktemp -d`
	#cd $t
	#wget http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/dhry.java \
	#  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/GlobalVariables.java \
	#  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/DhrystoneConstants.java \
	#  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/Record_Type.java || exit $?
	#patch < $wrkdir/patches/java_dhrystone.patch || exit $?
	#mv dhry.java dhrystone.java
	#cp *.java $wrkdir/benchmarks
	#rm -fr $t
}

# main

build_cpython
build_luajit
build_pypy
build_v8
build_gmake
build_jdk
build_graal
build_jruby_truffle
build_hhvm

fetch_external_benchmarks
