#! /bin/sh
url='https://raw.githubusercontent.com/zoff99/c-toxcore/zoff99/zoxcore_local_fork'

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

basedir="$_HOME_""/../"

mkdir -p "$basedir"/toxcore/
cd "$basedir"/toxcore/

wget "$url"/amalgamation/toxcore_amalgamation.c -O toxcore_amalgamation.c
wget "$url"/amalgamation/Makefile -O Makefile
mkdir -p tox/
cd tox/
wget -O tox.h "$url"/toxcore/tox.h
wget -O toxutil.h "$url"/toxutil/toxutil.h
wget -O toxav.h "$url"/toxav/toxav.h

