#! /bin/sh

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
check_for java
check_for javac
which gmake > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
    MYMAKE=gmake
else
    MYMAKE=make
fi

if [ $missing -eq 1 ]; then
    exit 1
fi

wrkdir=`pwd`/work
mkdir -p ${wrkdir}
echo "===> Working in $wrkdir"

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

build_pypy() {
	cd ${wrkdir} || exit $?
	echo "\n===> Download PyPy\n"
	PYPYV=2.3.1
	wget https://bitbucket.org/pypy/pypy/downloads/pypy-${PYPYV}-src.tar.bz2 || exit $?
	bunzip2 -c - pypy-${PYPYV}-src.tar.bz2 | tar xf -
	mv pypy-${PYPYV}-src pypy
	cd pypy/pypy/goal/
	echo "\n===> Build normal PyPy\n"
	usession=`mktemp -d`
	PYPY_USESSION_DIR=$usession $PYTHON ../../rpython/bin/rpython -Ojit --output=pypy || exit $?
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

	#wget https://github.com/v8/v8-git-mirror/archive/${V8_V}.tar.gz -O v8-${V8_V}.tar.gz || exit $?
	#tar xfz v8-${V8_V}.tar.gz || exit $?
	#mv v8-git-mirror-${V8_V}/ v8 || exit $?
	#cd ${wrkdir}/v8
	# The build actually requires that you clone using this git wrapper tool
	cd ${wrkdir}
	OLDPATH=${PATH}
	PATH=${wrkdir}/depot_tools:${PATH}
	fetch v8 || exit $?
	cd v8
	git checkout ${V8_V} || exit $?
	make native || exit $?
	PATH=${OLDPATH}
}


fetch_external_benchmarks() {
	echo "\n===> Download and build misc benchmarks\n"

cat << EOF
In order to build these benchmarks, you need to agree to the licensing terms
of the Java Richards benchmark at:
  http://web.archive.org/web/20050825101121/http://www.sunlabs.com/people/mario/java_benchmarking/index.html
EOF

	echo -n "Have you read and agreed to these terms? [Ny] "
	read answer
	case "$answer" in
	    y | Y) ;;
	    *) exit 1;;
	esac

	t=`mktemp -d`
	cd $t
	wget http://www.wolczko.com/richdbsrc.zip || exit $?
	unzip richdbsrc.zip || exit $?
	mv Benchmark.java Program.java COM/sun/labs/kanban/richards_deutsch_acc_virtual/ || exit $?
	cd COM/sun/labs/kanban/richards_deutsch_acc_virtual || exit $?
	mv Richards.java richards.java || exit $?
	patch < $wrkdir/patches/java_richards.patch || exit $?
	cp *.java $wrkdir/benchmarks || exit $?
	rm -fr $t

	t=`mktemp -d`
	cd $t
	wget http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/dhry.java \
	  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/GlobalVariables.java \
	  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/DhrystoneConstants.java \
	  http://hotpy.googlecode.com/svn-history/r96/trunk/benchmarks/java/Record_Type.java || exit $?
	patch < $wrkdir/patches/java_dhrystone.patch || exit $?
	mv dhry.java dhrystone.java
	cp *.java $wrkdir/benchmarks
	rm -fr $t
}

# main

build_cpython
build_luajit
#build_pypy
build_v8
