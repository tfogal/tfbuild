#!/bin/bash
# sh-style script to setup environment for tfbuild.

# pick up PREFIX:
. ${HOME}/build/bf.sh

PATH="${PREFIX}/bin:$PATH"

ACLOCAL="aclocal -I ${PREFIX}/share/aclocal"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PREFIX}/lib64"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PREFIX}/lib"
MANPATH="${MANPATH}:${PREFIX}/man:${PREFIX}/share/man"
PERL5LIB="${PREFIX}/lib/perl5/site_perl:${PERL5LIB}"
PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
PYTHONPATH="${PYTHONPATH}:${PREFIX}/lib64/python2.5/site-packages"
PYTHONPATH="${PYTHONPATH}:${PREFIX}/lib/python2.5/site-packages"
TEXINPUTS="${TEXINPUTS}:${PREFIX}/tftex"

# ugh.  do some hackery to remove duplicates from our path specifications.
# This happens when using programs like screen; the shell we logged into adds a
# path, starting an xterm would add paths, and then each shell-in-a-screen is a
# login shell, so would also add it's own paths.
function fixpath {
    # we need to separate the paths by newlines for sort and uniq to work
    pathlist=$(echo "${@}" | tr : \\n)

    unique=`echo -e "${pathlist}" | sort | uniq`

    # we can end up with a blank line after the sort, sometimes.  it will
    # always be the first line, so if the first line is a path we're already
    # all set -- otherwise get rid of the first couple bytes.
    ln1=`echo -e "${unique}" | head --bytes=1`
    if test "x${ln1}" = "x/" ; then
        # don't strip them -- it's a path!
        v=`echo -e "${unique}" | tr "\n" ":"`
    else
        v=`echo -e "${unique}" | tail --bytes=+2 | tr "\n" ":"`
    fi
    echo ${v}
}

if test `uname` = "Linux" ; then
    LD_LIBRARY_PATH=$(fixpath "${LD_LIBRARY_PATH}")
    MANPATH=$(fixpath "${MANPATH}")
    # fixpath fails for paths that are already good -- without redundant ":"'s,
    # etc.
    # PATH=$(fixpath "${PATH}")
    PKG_CONFIG_PATH=$(fixpath "${PKG_CONFIG_PATH}")
    PERL5LIB=$(fixpath "${PERL5LIB}")
    PYTHONPATH=$(fixpath "${PYTHONPATH}")
    TEXINPUTS=$(fixpath "${TEXINPUTS}")
fi

export ACLOCAL
export LD_LIBRARY_PATH
export MANPATH
export PATH
export PERL5LIB
export PKG_CONFIG_PATH
export PYTHONPATH
export TEXINPUTS
