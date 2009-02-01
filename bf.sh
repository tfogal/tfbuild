#!/bin/sh
# Build functionality

PREFIX="/scratch/sw"
JOBS=4

function download()
{
   if [ -z "$@" ]; then
      echo "Download _what_?"
      exit 1;
   fi
   wget -nv "$@"
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
        echo "Unknown file type!"
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
    export CFLAGS="${CFLAGS} -m64 -fPIC -I${PREFIX}/include"
    export CXXFLAGS="${CXXFLAGS} -m64 -fPIC -I${PREFIX}/include"
    export LDFLAGS="${LDFLAGS} -m64 -L${PREFIX}/lib64 -L${PREFIX}/lib"
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
