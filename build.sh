#! /bin/sh

unknown_platform() {
    echo "Unknown platform: `uname`"
    exit 1
}

missing=0
check_for () {
    which $1 > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: can't find $1 binary"
        missing=1
    fi
}

check_for ant
check_for cc
check_for g++
check_for bunzip2
check_for git
check_for hg
check_for python
check_for svn
check_for unzip
check_for xml2-config
check_for bash
check_for xzdec
check_for wget
check_for virtualenv
check_for zip

case `uname` in
    Linux*)
        PATCH_ARGS=--backup;;
    OpenBSD*)
        check_for gm4;;
esac


usage() {
    echo "Usage: build.sh [-f]" >&2
    exit 1
}

# How many cores does this machine have (so we can pass a sensible number to
# gmake -j)?
case `uname` in
    OpenBSD) max_jobs=`sysctl -n hw.ncpu`;;
    Linux) max_jobs=`nproc`;;
esac
# Keep max_jobs to safe limits for pretty much any machine out there.
if [ $max_jobs -le 0 ]; then
    max_jobs=1
elif [ $max_jobs -gt 8 ]; then
    max_jobs=8
fi

num_jobs=1
while getopts ":f" f
do
    case "$f" in
        f)   num_jobs=$max_jobs;;
        h)   usage;;
        [?]) usage;;
    esac
done


which pypy > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
    PYTHON=`which pypy`
else
    PYTHON=`which python2.7`
fi

# Let's use GNU make across the board
case `uname` in
    OpenBSD) GMAKE=gmake;;
    Linux) GMAKE=make;;
    *) unknown_platform;;
esac
check_for ${GMAKE}

if [ $missing -eq 1 ]; then
    exit 1
fi

HERE=`pwd`
wrkdir=${HERE}/work
PATCH_DIR=${HERE}/patches
ARCHIVE_DISTFILES=https://archive.org/download/softdev_warmup_experiment_artefacts/distfiles/

mkdir -p ${wrkdir}
echo "===> Working in $wrkdir"

PATCH_DIR=`pwd`/patches/

# System (from OS packages) Java 7, for making a JDK8. We must not use a JDK8
# to build a JDK8. See README-builds.html in JDK8 src tarball.
case `uname` in
    Linux)
        SYS_JDK7_HOME=/usr/lib/jvm/java-7-openjdk-amd64
        SYS_JDK8_HOME=/usr/lib/jvm/java-8-openjdk-amd64
        ;;
    OpenBSD)
        SYS_JDK7_HOME=/usr/local/jdk-1.7.0
        SYS_JDK8_HOME=/not_used_on_openbsd
        ;;
    *) unknown_platform;;
esac

if [ ! -d ${SYS_JDK7_HOME} ]; then
    echo "Can't find system Java 7"
    exit 1
fi

WARMUP_STATS_VERSION=726eaa39930c9dabc0df8fcef7a42b7f6465001d
build_warmup_stats() {
    echo "\n===> Download and build stats\n"
    # Older OpenBSDs don't have a new enough libzip
    if [ "`uname`" = "OpenBSD" ]; then
        ${PYTHON} -c "import sys; sys.exit(`uname -r` < 6.2)"
        if [ $? != 0 ]; then
            echo "skipping warmup_stats"
            return
        fi
    fi
    if ! [ -d "${HERE}/warmup_stats" ]; then
        cd ${HERE} && git clone https://github.com/softdevteam/warmup_stats || exit $?
    fi
    cd ${HERE}/warmup_stats && git checkout ${WARMUP_STATS_V} || exit $?
    if ! [ -d "${HERE}/warmup_stats/work/R-inst" ]; then
        cd ${HERE}/warmup_stats && ./build.sh || exit $?
    fi
}

KRUN_VERSION=33720eb442c504ea1a02e578aa4a8631398403f2
build_initial_krun() {
    echo "\n===> Download and build krun\n"
    if ! [ -d "${HERE}/krun" ]; then
        cd ${HERE} && git clone --recursive https://github.com/softdevteam/krun.git || exit $?
    fi

    # We do a quick build now so that VMs which link libkruntime can find it.
    # Note that we will build again later once we have the JVM built, so that
    # libkruntime can itself be built with Java support.
    #
    # Due to the above, We don't care what compiler we use at this stage.
    cd ${HERE}/krun && git checkout ${KRUN_VERSION} && ${GMAKE} || exit $?
}

clean_krun() {
    # See build_initial_krun() comment for why this exists
    cd ${HERE}/krun && ${GMAKE} clean || exit $?
}

# We build our own fixed version of GCC, thus ruling out differences in
# packaged compilers for the different platforms.
GCC_V=4.9.4
OUR_CC=${wrkdir}/gcc-inst/bin/zgcc
OUR_CXX=${wrkdir}/gcc-inst/bin/zg++
GCC_TARBALL_URL=ftp://ftp.mirrorservice.org/sites/ftp.gnu.org/gnu/gcc/gcc-${GCC_V}/gcc-${GCC_V}.tar.gz
build_gcc() {
    echo "\n===> Download and build GCC\n"
    if [ -f ${OUR_CC} ]; then return; fi
    cd ${wrkdir}
    if ! [ -f ${wrkdir}/gcc-${GCC_V}.tar.gz ]; then
        wget ${GCC_TARBALL_URL} || exit $?
    fi
    if ! [ -d ${wrkdir}/gcc ]; then
        tar xfzp gcc-${GCC_V}.tar.gz || exit $?;
        mv gcc-${GCC_V} gcc || exit $?
    fi
    cd gcc || exit $?

    if [ `uname` = "OpenBSD" ]; then
        for p in `ls ${PATCH_DIR}/openbsd_gcc_patches`; do
            patch -Ep0 < ${PATCH_DIR}/openbsd_gcc_patches/$p || exit $?
        done
    fi

    # download script uses fixed versions, so OK.
    ./contrib/download_prerequisites || exit $?

    mkdir sd_build || exit $?
    cd sd_build || exit $?

    ../configure \
        --prefix=${wrkdir}/gcc-inst \
        --disable-libcilkrts \
        --program-transform-name=s,^,z, \
        --verbose \
        --disable-libmudflap \
        --disable-libgomp \
        --disable-multilib \
        --disable-tls \
        --enable-languages=c,c++ \
        --with-system-zlib \
        --disable-tls \
        --enable-threads=posix \
        --enable-wchar_t \
        --disable-libstdcxx-pch \
        --enable-cpp \
        --enable-shared \
      || exit $?
    ${GMAKE} -j $num_jobs || exit $?
    ${GMAKE} install || exit $?
}

apply_gcc_lib_path() {
    # Put GCC libs into linker path
    # Needed for (e.g.) V8 to find libstdc++
    case `uname` in
        Linux) export LD_LIBRARY_PATH=${wrkdir}/gcc-inst/lib64;;
        OpenBSD) export LD_LIBRARY_PATH=${wrkdir}/gcc-inst/lib;;
        *) unknown_platform;;
    esac
}

# CPython is used to build V8. Debian 8 package is too old.
CPYTHONV=2.7.12
CPYTHON=${wrkdir}/cpython-inst/bin/python
build_cpython() {
    cd ${wrkdir} || exit $?
    echo "\n===> Download and build CPython\n"
    if [ -f ${wrkdir}/cpython/python ]; then return; fi
    cd $wrkdir
    if [ ! -f Python-${CPYTHONV}.tgz ]; then
        wget http://python.org/ftp/python/${CPYTHONV}/Python-${CPYTHONV}.tgz || exit $?
    fi
    tar xfz Python-${CPYTHONV}.tgz || exit $?
    mv Python-${CPYTHONV} cpython
    cd cpython

    case `uname` in
        OpenBSD)
            CC=${OUR_CC} LDFLAGS=-Wl,-z,wxneeded ./configure \
                --prefix=${wrkdir}/cpython-inst || exit $?;;
        *)
            CC=${OUR_CC} ./configure \
                --prefix=${wrkdir}/cpython-inst || exit $?;;
    esac

    ${GMAKE} -j $num_jobs || exit $?
    ${GMAKE} install || exit $?
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
    CFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT ${GMAKE} CC=${OUR_CC} || exit $?
}

PYPYV=5.7.1
build_pypy() {
    cd ${wrkdir} || exit $?
    echo "\n===> Download and build PyPy\n"
    if [ -f ${wrkdir}/pypy/pypy/goal/pypy-c ]; then return; fi

    if ! [ -f "${wrkdir}/pypy2-v${PYPYV}-src.tar.bz2" ]; then
        url="https://bitbucket.org/pypy/pypy/downloads/pypy2-v${PYPYV}-src.tar.bz2"
        case `uname` in
            OpenBSD) ftp $url || exit $?;;
            *) wget $url || exit $?;;
        esac
    fi

    if ! [ -d "${wrkdir}/pypy" ]; then
        bunzip2 -c - pypy2-v${PYPYV}-src.tar.bz2 | tar xf - || exit $?
        mv pypy2-v${PYPYV}-src pypy || exit $?
        cd pypy
        patch -p0 < ${PATCH_DIR}/pypy.diff || exit $?
    fi

    cd ${wrkdir}/pypy/pypy/goal/ || exit $?
    usession=`mktemp -d`

    # Separate translate/compile so we can tag on W^X flag.
    env CC=${OUR_CC} PYPY_USESSION_DIR=${usession} \
        ${PYTHON} ../../rpython/bin/rpython -Ojit --source --no-shared \
        || exit $?

    pypy_make_dir=${usession}/usession-release-pypy2.7-v${PYPYV}-0/testing_1
    cd ${pypy_make_dir} || exit $?
    case `uname` in
        OpenBSD)
            env CC=${OUR_CC} ${GMAKE} LDFLAGSEXTRA="-Wl,-z,wxneeded" || exit $?;;
        *)
            env CC=${OUR_CC} ${GMAKE} || exit $?;;
    esac

    cp ${pypy_make_dir}/pypy-c ${wrkdir}/pypy/pypy/goal/pypy-c || exit $?
    rm -rf ${usession}
}

# We build V8 using a hand rolled tarball. See bin/make_v8_source_tarball.
V8_V=5.8.283.32
V8_TARBALL=v8_fullsource_${V8_V}_2017-12-12.tar.gz

build_v8() {
    cd ${wrkdir} || exit $?
    echo "\n===> Download and build V8\n"

    if [ -f ${wrkdir}/v8/out/native/d8 ]; then return; fi

    if ! [ -f ${wrkdir}/${V8_TARBALL} ]; then
        cd ${wrkdir}/ && wget ${ARCHIVE_DISTFILES}/${V8_TARBALL} || exit $?
    fi

    tar zxf ${V8_TARBALL} || exit $?
    cd ${wrkdir}/v8 || exit $?
    patch -Ep1 < ${PATCH_DIR}/v8.diff || exit $?

    cd ${wrkdir}/v8/tools/clang || exit $?
    patch -Ep1 < ${PATCH_DIR}/v8_clang.diff || exit $?

    # Test suite build doesn't listen to CC/CXX -- symlink/path hack ahoy
    ln -sf ${OUR_CC} `dirname ${OUR_CC}`/gcc
    ln -sf ${OUR_CXX} `dirname ${OUR_CXX}`/g++
    PATH=`dirname ${OUR_CC}`:${PATH}

    # V8 mistakes our compiler for clang for some reason, hence setting
    # GYP_DEFINES. It probably isn't expecting a gcc to be called zgcc.
    cd ${wrkdir}/v8 || exit $?
    env GYP_DEFINES="clang=0" CC=${OUR_CC} CXX=${OUR_CXX} \
        LIBKRUN_DIR=${HERE}/krun/libkrun ${GMAKE} -j${num_jobs} native V=1 || exit $?
    test -f out/native/d8 || exit $?

    # remove the gcc/g++ symlinks from earlier and restore path
    rm `dirname ${OUR_CC}`/gcc `dirname ${OUR_CC}`/g++ || exit $?
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
    CC=${OUR_CC} ./configure || exit $?
    ${GMAKE} JOBS=$num_jobs || exit $?
    cp make gmake
}

# We use the JDK we just built for all consequent Java compilation (and as a
# basis for the Graal compiler).
case `uname` in
    Linux)   OUR_JAVA_HOME=${wrkdir}/openjdk/build/linux-x86_64-normal-server-release/images/j2sdk-image/;;
    OpenBSD) OUR_JAVA_HOME=${wrkdir}/openjdk/build/bsd-x86_64-normal-server-release/images/j2sdk-image/;;
    *) unknown_platform;;
esac
JDK_TARBALL_BASE=openjdk-8u121b13-bsd-port-20170201
build_jdk() {
    echo "\n===> Download and build JDK8\n"
    if [ -f ${OUR_JAVA_HOME}/bin/javac ]; then return; fi
    cd ${wrkdir} || exit $?
    if ! [ -f "${wrkdir}/${JDK_TARBALL_BASE}.tar.xz" ]; then
        wget http://www.intricatesoftware.com/distfiles/${JDK_TARBALL_BASE}.tar.xz || exit $?
    fi
    if ! [ -d ${wkrdir}/openjdk ]; then
        xzdec ${JDK_TARBALL_BASE}.tar.xz | tar xf - || exit $?
        mv ${JDK_TARBALL_BASE} openjdk
    fi
    cd openjdk || exit $?
    JDK_BUILD_PATH=`dirname ${OUR_CC}`:${PATH}
    case `uname` in
        Linux)
            env CC=zgcc CXX=zg++ PATH=${JDK_BUILD_PATH} bash configure \
                --disable-option-checking \
                --with-cups-include=/usr/local/include \
                --with-debug-level=release \
                --with-debug-level=release \
                --disable-ccache \
                --disable-freetype-bundling \
                --disable-zip-debug-info \
                --disable-debug-symbols \
                --enable-static-libjli \
                --with-zlib=system \
                --with-milestone=fcs \
                --with-jobs=$num_jobs \
                --with-boot-jdk=${SYS_JDK7_HOME} \
                || exit $?
            PATH=${JDK_BUILD_PATH} ../make-${GMAKE_V}/make all || exit $?
            ;;
        OpenBSD)
            env CPPFLAGS=-I/usr/local/include \
              CC=zgcc CXX=zg++ PATH=${JDK_BUILD_PATH} ac_cv_path_NAWK=awk bash configure \
              --disable-option-checking \
              --with-cups-include=/usr/local/include \
              --with-debug-level=release \
              --with-debug-level=release \
              --disable-ccache \
              --disable-freetype-bundling \
              --disable-zip-debug-info \
              --disable-debug-symbols \
              --enable-static-libjli \
              --with-zlib=system \
              --with-giflib=system \
              --with-milestone=fcs \
              --with-jobs=$num_jobs \
              --with-extra-ldflags="-Wl,-z,wxneeded" \
              --with-boot-jdk=${SYS_JDK7_HOME} \
              || exit $?
            PATH=${JDK_BUILD_PATH} \
                COMPILER_WARNINGS_FATAL=false \
                DEFAULT_LIBPATH="/usr/lib:/usr/X11R6/lib:/usr/local/lib"\
                ../make-${GMAKE_V}/make all || exit $?
            ;;
        *)
            unknown_platform;;
    esac
    # JDK installs some jar files unreadable to "other" users meaning that the
    # benchmark user can't access them. This becomes a problem later for graal,
    # which takes a copy of this JDK's jar files.
    chmod -R 755 ${wrkdir}/openjdk/build/*-release/jdk/lib || exit $?
}


# This is a bootstrap JDK used only for Graal, which requiries a very specific
# version of the JDK.
BOOT_JDK_UPDATE_V=121
BOOT_JDK_BUILD_V=13
BOOT_JAVA_V=8u${BOOT_JDK_UPDATE_V}-b${BOOT_JDK_BUILD_V}
BOOT_JAVA_HOME=${wrkdir}/jdk${BOOT_JAVA_V}_fullsource/build/linux-x86_64-normal-server-release/images/j2sdk-image/
BOOT_JDK_BASE=jdk${BOOT_JAVA_V}
BOOT_JDK_TAR=${BOOT_JDK_BASE}_fullsource.tgz
build_bootstrap_jdk() {
    echo "\n===> Download and build graal bootstrap JDK8\n"
    if [ -f ${BOOT_JAVA_HOME}/bin/javac ]; then return; fi

    cd ${wrkdir} || exit $?
    # We fetch a hand-rolled tarball, as the JDK repo build downloads things
    # and I am not sure that they are fixed versions. The tarball was rolled on
    # 2017-04-19 to match the current OTN build, which at the time was:
    # labsjdk-8u121-jvmci-0.25-darwin-amd64.tar.gz
    #
    # To build the JDK8 tarball:
    #   hg clone http://hg.openjdk.java.net/jdk8u/jdk8u openjdk8
    #   hg up <tag>  # plug in the right tag, e.g. `jdk8u121-b13'
    #   sh get_source.sh
    #   find . -name '.hg' -type 'd' | xargs rm -rf
    #   cd ..
    #   mv openjdk8 ${BOOT_JDK_BASE}_fullsource
    #   tar zcvf ${BOOT_JDK_BASE}_fullsource.tgz ${BOOT_JDK_BASE}_fullsource
    #   Upload to archive.org once tested
    if [ ! -f ${wrkdir}/${BOOT_JDK_TAR} ]; then
        wget ${ARCHIVE_DISTFILES}/${BOOT_JDK_TAR}
    fi
    if [ ! -d ${BOOT_JDK_BASE}_fullsource ]; then
        tar zxf ${BOOT_JDK_TAR} || exit $?
    fi

    cd  ${BOOT_JDK_BASE}_fullsource || exit $?
    JDK_BUILD_PATH=`dirname ${OUR_CC}`:${PATH}
    env CC=zgcc CXX=zg++ PATH=${JDK_BUILD_PATH} bash configure \
        --disable-option-checking \
        --with-cups-include=/usr/local/include \
        --with-debug-level=release \
        --with-debug-level=release \
        --disable-ccache \
        --disable-freetype-bundling \
        --disable-zip-debug-info \
        --disable-debug-symbols \
        --enable-static-libjli \
        --with-zlib=system \
        --with-milestone=fcs \
        --with-jobs=$num_jobs \
        --with-boot-jdk=${SYS_JDK7_HOME} \
        --with-update-version=${BOOT_JDK_UPDATE_V} \
        --with-build-number=b${BOOT_JDK_BUILD_V} \
        || exit $?
    PATH=${JDK_BUILD_PATH} ../make-${GMAKE_V}/make all || exit $?
}

# The latest Graal and MX at the time of writing. Note that Graal will be part
# of JDK9 soon, so the build steps you see here will be out of date soon. Also
# note that MX doesn't have releases.
JVMCI_VERSION=jvmci-0.25
MX_VERSION=720976e8c52527416f7aec95262c9a47d93602c4
GRAAL_VERSION=graal-vm-0.22
build_graal() {
    echo "\n===> Download and build graal\n"

    if [ -f ${wrkdir}/graal-jvmci-8/jdk1.8*/product/bin/javac ]; then return; fi

    if [ ! -d ${wrkdir}/mx ]; then
        cd ${wrkdir} && git clone https://github.com/graalvm/mx || exit $?
        cd mx && git checkout ${MX_VERSION} && cd .. || exit $?
    fi

    # mx won't listen to CC/CXX
    ln -sf ${OUR_CC} `dirname ${OUR_CC}`/gcc
    ln -sf ${OUR_CXX} `dirname ${OUR_CXX}`/g++
    GRAAL_PATH=`dirname ${OUR_CC}`:${PATH}
    MX="env PATH=${GRAAL_PATH} python2.7 ${wrkdir}/mx/mx.py --java-home ${BOOT_JAVA_HOME}"

    # Build a JVMCI-enabled JDK
    if [ ! -d ${wrkdir}/graal-jvmci-8 ];then
        hg clone http://hg.openjdk.java.net/graal/graal-jvmci-8
    fi
    cd graal-jvmci-8 || exit $?
    hg up ${JVMCI_VERSION} || exit $?
    if [ ! -d ${wrkdir}/graal-jvmci-8/jdk1.8.0 ]; then
        ${MX} sforceimports || exit $?
        ${MX} build || exit $?
    fi

    # Make mx use the jvmci-enabled jdk
    cd ${wrkdir}/graal-jvmci-8
    JVMCI_JAVA_HOME=`${MX} jdkhome`
    echo "jvmci JAVA_HOME is: ${JVMCI_JAVA_HOME}"
    MX="env PATH=${GRAAL_PATH} python2.7 ${wrkdir}/mx/mx.py --java-home ${JVMCI_JAVA_HOME}"

    # Build graal itself
    cd ${wrkdir}
    if ! [ -d ${wrkdir}/graal ]; then
        git clone https://github.com/graalvm/graal-core graal || exit $?
    fi
    cd ${wrkdir}/graal && git checkout ${GRAAL_VERSION} || exit $?
    ${MX} sforceimports || exit $?
    ${MX} || exit $?  # fetches truffle
    cd ${wrkdir}/truffle && git checkout ${GRAAL_VERSION} || exit $?
    cd ${wrkdir}/graal && ${MX} build || exit $?

    # remove the symlinks
    rm `dirname ${OUR_CC}`/gcc `dirname ${OUR_CC}`/g++ || exit $?
}

# We had problems with offline mode in maven2, which at the time of writing is
# the version in Debian stable packages. We download a newer version from the
# 3.x branch.
MAVEN_V=3.5.0
MAVEN_TARBALL=apache-maven-${MAVEN_V}-bin.tar.gz
MAVEN_TARBALL_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_V}/binaries/${MAVEN_TARBALL}
fetch_maven() {
    echo "\n===> Fetch Maven\n"
    cd ${wrkdir}

    if ! [ -f ${wrkdir}/${MAVEN_TARBALL} ]; then
       wget ${MAVEN_TARBALL_URL} || exit $?
    fi

    if ! [ -d ${wrkdir}/maven ]; then
        tar zxvf ${MAVEN_TARBALL} && mv apache-maven-${MAVEN_V} maven || exit $?
    fi

    # Put maven into the PATH
    export PATH=${wrkdir}/maven/bin:${PATH}
    if [ "`which mvn`" != "${wrkdir}/maven/bin/mvn" ]; then
        echo "The mvn we installed is not in the path correctly"
        exit 1
    fi
}


TRUFFLERUBY_V=graal-vm-0.22
TRUFFLERUBY_BUILDPACK_DIR=${wrkdir}/truffleruby-buildpack
TRUFFLERUBY_BUILDPACK_TARBALL=truffleruby-buildpack-${TRUFFLERUBY_V}-20170502.tgz
build_truffleruby() {
    echo "\n===> Download and build TruffleRuby\n"

    # maven caches dependencies, we dont ever want to pick those up, only
    # what's in the jruby build pack.
    if [ -e "~/.m2"  ] || [ -e "~/.maven-gems" ]; then
        echo "Please remove your maven configurations: ~/.m2 ~/.maven-gems";
        exit $?
    fi

    cd ${wrkdir}
    if [ -f ${wrkdir}/truffleruby/truffleruby/target/truffleruby-0-SNAPSHOT.jar ]; then return; fi
    if ! [ -d ${wrkdir}/truffleruby ]; then
        git clone https://github.com/graalvm/truffleruby.git || exit $?
        cd ${wrkdir}/truffleruby
        git checkout ${TRUFFLERUBY_V} || exit $?
        patch -Ep1 < ${PATCH_DIR}/truffleruby.diff || exit $?
    fi

    cd ${wrkdir}
    if [ ! -f ${TRUFFLERUBY_BUILDPACK_TARBALL} ]; then
        wget ${ARCHIVE_DISTFILES}/${TRUFFLERUBY_BUILDPACK_TARBALL} || exit $?
    fi
    if [ ! -d ${TRUFFLERUBY_BUILDPACK_DIR} ]; then
        cd ${wrkdir} && tar zxvf ${TRUFFLERUBY_BUILDPACK_TARBALL} || exit $?
    fi

    cd ${wrkdir}/truffleruby || exit $?

    # To make a buildpack, you would do:
    #   env JAVA_HOME=${SYS_JDK8_HOME} mvn -X \
    #       -Dmaven.repo.local=${TRUFFLERUBY_BUILDPACK_DIR} || exit 1
    # Then tar up the resultant directory, test it, and host on archive.org.

    # We have to use the system JDK8 since the one we bootstrap doesn't have
    # SSL configured (jdk has its own CA cert format). See:
    # http://www.linuxfromscratch.org/blfs/view/svn/general/openjdk.html
    env MVN_EXTRA_ARGS="-Dmaven.repo.local=${TRUFFLERUBY_BUILDPACK_DIR} --offline" \
        V=1 JAVA_HOME=${SYS_JDK8_HOME} ruby tool/jt.rb build || exit $?

    # To invoke the VM:
    #   PATH=${PATH}:/path/to/work/mx \
    #     JAVA_HOME=/path/to/work/graal-jvmci-8/jdk1.8.0_121/product \
    #     GRAAL_HOME=/path/to/work/graal \
    #     ../truffleruby/tool/jt.rb run --graal
    #
    # Check it has the JIT by evaluating (should be true):
    #  Truffle::Graal.graal?
}


HHVM_VERSION=HHVM-3.19.1
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
    patch -Ep1 < ${PATCH_DIR}/hhvm.diff || exit $?

    # Some parts of the build (e.g. OCaml) won't listen to CC/CXX
    ln -sf ${OUR_CC} `dirname ${OUR_CC}`/gcc || exit $?
    ln -sf ${OUR_CXX} `dirname ${OUR_CXX}`/g++ || exit $?
    HHVM_PATH=`dirname ${OUR_CC}`:${PATH}

    # -DBUILD_HACK=OFF since we only need the PHP part of HHVM (faster build)
    # -DENABLE_EXTENSION_LZ4=OFF: https://github.com/facebook/hhvm/issues/7804
    env LIBKRUN_DIR=${HERE}/krun/libkrun PATH=${HHVM_PATH} CC=${OUR_CC} \
        CXX=${OUR_CXX} sh -c "cmake -DCMAKE_CXX_FLAGS=-I${HERE}/krun/libkrun -DENABLE_EXTENSION_LZ4=OFF -DBUILD_HACK=OFF ." || exit $?
    ${GMAKE} -j $num_jobs VERBOSE=1 || exit $?

    # remove the symlinks
    rm `dirname ${OUR_CC}`/gcc `dirname ${OUR_CC}`/g++ || exit $?
}


# autoconf-2.13 is needed to build spidermonkey
build_autoconf() {
    echo "\n===> Download and build autoconf-2.13\n"
    if [ -d ${wrkdir}/autoconf-2.13 ]; then return; fi
    cd ${wrkdir} || exit $?
    wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz || exit $?
    tar xfz autoconf-2.13.tar.gz || exit $?
    cd autoconf-2.13
    ./configure --prefix=${wrkdir}/autoconf-inst || exit $?
    make install || exit $?
    cd ${wrkdir}/autoconf-inst/bin
    ln -s autoconf autoconf-2.13 || exit $?
    cd ${HERE}
}


SPIDERMONKEY_VERSION=6583496f169c # FIREFOX_AURORA_54_BASE
build_spidermonkey() {
    echo "\n===> Download and build SpiderMonkey\n"
    if [ -d ${wrkdir}/spidermonkey ]; then return; fi
    cd ${wrkdir} || exit $?
    wget -O spidermonkey.tar.bz2 http://hg.mozilla.org/mozilla-central/archive/${SPIDERMONKEY_VERSION}.tar.bz2 || exit $?
    bunzip2 -c - spidermonkey.tar.bz2 | tar xfp - || exit $?
    mv mozilla-central-${SPIDERMONKEY_VERSION} spidermonkey || exit $?
    cd spidermonkey
    cd js/src
    ${wrkdir}/autoconf-inst/bin/autoconf || exit $?
    mkdir build_OPT.OBJ
    cd build_OPT.OBJ
    AUTOCONF=${wrkdir}/autoconf-inst/bin/autoconf-2.13 MOZ_JEMALLOC4=1 CC=${OUR_CC} CXX=${OUR_CXX} ../configure --disable-tests || exit $?
    LD_LIBRARY_PATH=${wrkdir}/gcc-inst/lib/ ${GMAKE} -j $num_jobs || exit $?
}


build_dacapo() {
    echo "\n===> Build DaCapo\n"

    if [ -f "${HERE}/extbench/dacapo-9.12-bach.jar" ]; then return; fi

    # DaCapo uses a millisecond timer by default, which isn't good enough for
    # our purposes. To fix this, in as minimally intrusive a way as possible: we
    # download the DaCapo binary and source distributions; unpack both; patch
    # the source version and recompile only the benchmarking harness; copy the
    # relevant recompiled .class files back into the binary distribution; and
    # rezip it. Thus the DaCapo jar we end up running is only minimally changed.

    cd ${wrkdir}
    mkdir -p dacapo
    cd dacapo
    wget "https://sourceforge.net/projects/dacapobench/files/archive/9.12-bach/dacapo-9.12-bach-src.zip/download" -O dacapo-9.12-bach.src.zip || exit $?
    mkdir -p src
    cd src
    unzip ../dacapo-9.12-bach.src.zip || exit $?
    cd benchmarks/harness/src/org/dacapo/harness/
    patch -p0 < ${HERE}/patches/dacapo.diff || exit $?
    cd ${wrkdir}/dacapo/src/benchmarks
    ant harness || exit $?

    cd ${wrkdir}/dacapo
    wget "http://downloads.sourceforge.net/project/dacapobench/archive/9.12-bach/dacapo-9.12-bach.jar?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fdacapobench%2Ffiles%2F&ts=1474888492&use_mirror=freefr" -O dacapo-9.12-bach.jar  || exit $?
    mkdir bin
    cd bin
    unzip ../dacapo-9.12-bach.jar || exit $?
    cp ../src/benchmarks/harness/dist/org/dacapo/harness/Callback*.class org/dacapo/harness/ || exit $?
    zip -r ${HERE}/extbench/dacapo-9.12-bach.jar ./*
}


OCTANE_V=4852334f
fetch_octane() {
    echo "\n===> Download Octane\n"

    if [ -d "${HERE}/extbench/octane" ]; then return; fi

    cd ${HERE}/extbench
    git clone https://github.com/chromium/octane || exit $?
    cd octane
    git checkout ${OCTANE_V} || exit $?
    patch < ${PATCH_DIR}/octane.diff || exit $?
    cp ${PATCH_DIR}/octane_run_we.js run_we.js || exit $?
}


build_external_benchmarks() {
    echo "\n===> Download and build misc benchmarks\n"

    if [ -f "${HERE}/benchmarks/richards/java/richards.java" ]; then return; fi

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
    wget https://archive.org/download/richards-benchmark/richdbsrc.zip || exit $?
    unzip richdbsrc.zip || exit $?
    mv Benchmark.java Program.java COM/sun/labs/kanban/richards_deutsch_acc_virtual/ || exit $?
    cd COM/sun/labs/kanban/richards_deutsch_acc_virtual || exit $?
    mv Richards.java richards.java || exit $?
    cp *.java ${HERE}/benchmarks/richards/java || exit $?
    cd ${HERE}/benchmarks/richards/java || exit $?
    patch ${PATCH_ARGS} < ${PATCH_DIR}/java_richards.diff || exit $?
    rm -fr $t
}


LIBKALIBERA_VERSION=95a9207515139a3f49114d965a163ddd5576c857
fetch_libkalibera() {
    echo "\n===> Fetch libkalibera\n"
    cd ${wrkdir}
    if ! [ -d libkalibera ]; then \
        git clone https://github.com/softdevteam/libkalibera.git || exit $?
        cd ${wrkdir}/libkalibera || exit $?
        git checkout ${LIBKALIBERA_VERSION} || exit $?
    fi
}

build_warmup_stats
build_external_benchmarks
build_initial_krun
build_dacapo
fetch_octane
build_gcc
apply_gcc_lib_path
fetch_libkalibera
build_cpython
build_luajit
build_pypy
build_v8
build_gmake
build_jdk
case `uname` in
    Linux)
        build_bootstrap_jdk
        build_graal
        fetch_maven
        build_truffleruby
        build_hhvm
        build_autoconf
        build_spidermonkey
    ;;
esac
clean_krun
