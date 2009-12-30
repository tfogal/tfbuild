#!/bin/sh
# Build functionality

PREFIX="${HOME}/sw"
JOBS=4

function download()
{
    if [ -z "$@" ]; then
        echo "Download _what_?"
        exit 1;
    fi
    # Thanks, Darwin.
    if test `uname` = "Darwin" ; then
        curl -kLO "$@"
    else
        wget -nv "$@"
    fi
}
function src_download()
{
    if [ -z "${URL}" ]; then
        echo "URL unset!  What are we dling?";
        exit 1;
    fi
    download "${URL}"
}

function src_extract()
{
    # If the client script didn't give a tarball, try to supply one.
    if test -z "${TARBALL}" ; then
        TARBALL=$(basename ${URL})
    fi
    # chop off the common extension.  If it changes, thats the right type.
    if [ "${TARBALL%%bz2}" != "${TARBALL}" ] ; then
        # Bzip2.
        tar jxf "${TARBALL}"
    elif [ "${TARBALL%%gz}" != "${TARBALL}" ] ; then
        # gzip
        tar zxf "${TARBALL}"
    elif [ "${TARBALL%%zip}" != "${TARBALL}" ] ; then
        # zip
        unzip "${TARBALL}"
    else
        printf "Unknown file type for file '%s'" ${TARBALL}
        exit 1
    fi
}

function src_configure()
{
    ./configure $@ --prefix="${PREFIX}"
    if [ $? != 0 ]; then
        echo "Configuration failed!  Bailing out..."
        exit 1
    fi
}

function src_make()
{
    # don't add jobs option if not set
    if [ -z "${JOBS}" ]; then
        nice -n 15 make $@
    else
        nice -n 15 make -j${JOBS} $@
    fi
}

function src_install()
{
    make install $@ || exit 1
}

function setup()
{
    mkdir -p ${PREFIX}/tmp/work
    pushd ${PREFIX}/tmp/work || exit 1
}
function teardown()
{
    popd
    rm -fr ${PREFIX}/tmp/work
}

function src_cd()
{
    # chop off the common extension.  If it changes, thats the right type.
    if [[ -n "${DIR}" ]] ; then
        cd "${DIR}" || exit 1
    elif [ "${TARBALL%%bz2}" != "${TARBALL}" ] ; then
        cd "${TARBALL%%.tar.bz2}" || exit 1
    elif [ "${TARBALL%%tar.gz}" != "${TARBALL}" ] ; then
        cd "${TARBALL%%.tar.gz}" || exit 1
    elif [ "${TARBALL%%tgz}" != "${TARBALL}" ] ; then
        cd "${TARBALL%%.tgz}" || exit 1
    elif [ "${TARBALL%%zip}" != "${TARBALL}" ] ; then
        cd "${TARBALL%%.zip}" || exit 1
    else
        cd "${TARBALL}" || exit 1
    fi
}

function setup_env()
{
    # Add our custom path to the build configuration flags.
    export CFLAGS="${CFLAGS} -fPIC -I${PREFIX}/include"
    export CXXFLAGS="${CXXFLAGS}  -fPIC -I${PREFIX}/include"
    export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib64 -L${PREFIX}/lib"
}

function gnu_pkg()
{
    setup
    src_download
    src_extract
    src_cd

    setup_env
    src_configure --disable-dependency-tracking $@
    src_make
    src_install
    teardown
}

function cmake_pkg()
{
    setup
    src_download
    src_extract
    src_cd

    setup_env
    # CMake has this annoying property that an initial run can
    # determine it *should look* for some optional libraries, but not
    # actually look for them.  So our first run figures out the basics,
    # and a second one makes sure that all optional libraries (that is,
    # libraries which aren't searched unless some pkg-specific BOOL is
    # ON) are searched for.
    for i in 1 2 ; do
        args="."
        if test -n "$@" ; then
          args="$@ ."
        fi

        cmake \
            -DCMAKE_INSTALL_PREFIX:PATH="${PREFIX}" \
            -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON        \
            -DCMAKE_C_FLAGS:STRING="${CFLAGS}"      \
            -DCMAKE_CXX_FLAGS:STRING="${CXXFLAGS}"  \
            -DBUILD_SHARED_LIBS:BOOL=ON \
            ${args} || exit 1
    done

    src_make
    src_install
    teardown
}

function python_pkg()
{
    setup
    src_download
    src_extract
    src_cd

    setup_env
    python setup.py build || exit 1
    python setup.py build_clib --prefix=${PREFIX} || exit 1
    python setup.py install --prefix=${PREFIX} || exit 1
    teardown
}
