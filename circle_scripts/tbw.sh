#! /bin/bash

_HOME_="$(pwd)"
export _HOME_

cd "$1"
_TBW_SRC_DIR_="$(pwd)"
export _TBW_SRC_DIR_

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/


export CF2=" -O3 -g"
export CF3=" "
export VV1=" VERBOSE=1 V=1 "


mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/
export PKG_CONFIG_PATH=$_INST_/lib/pkgconfig


# ------- ASTYLE 3.1 -------
cd "$_SRC_"
cd astyle/build_astyle/
export astyle_bin="$(pwd)/astyle"
"$astyle_bin" --version || exit 1
# ------- ASTYLE 3.1 -------


cd "$_SRC_"
cp -av "$_TBW_SRC_DIR_"/* ./ | tail -15

mkdir -p tbw2
cp -a toxblinkenwall/ tbw2/
cd tbw2/toxblinkenwall/

"$astyle_bin" --suffix=none --options=../../astyle/astylerc \
  rb.c rb.h ringbuf.c ringbuf.h \
  toxblinkenwall.c \
  openGL/esShader.c openGL/esUtil.c openGL/esUtil.h || exit 1

rm -f tbw_formatted.tgz
tar -czvf tbw_formatted.tgz \
  rb.c rb.h ringbuf.c ringbuf.h \
  toxblinkenwall.c \
  openGL/esShader.c openGL/esUtil.c openGL/esUtil.h

# --> tbw_formatted.tgz
cp -av tbw_formatted.tgz ~/work/deploy/

cd ../../
cd toxblinkenwall/

sed -i -e 's/#define HAVE_OUTPUT_OPENGL /#define HAVE_FRAMEBUFFER /' toxblinkenwall.c
cat toxblinkenwall.c|grep '^#define HAVE_OUTPUT_OPENGL'
cat toxblinkenwall.c|grep '^#define HAVE_FRAMEBUFFER'

# make certain warnings into errors!
WARNS=' '

gcc \
$CF2 $CF3 \
$WARNS \
-fstack-protector-all \
-Wno-unused-variable \
-fPIC -export-dynamic -I$_INST_/include -o toxblinkenwall -lm \
toxblinkenwall.c rb.c \
-std=gnu99 \
-L$_INST_/lib \
$_INST_/lib/libtoxcore.a \
$_INST_/lib/libtoxav.a \
-lrt \
$_INST_/lib/libopus.a \
$_INST_/lib/libvpx.a \
$_INST_/lib/libx264.a \
$_INST_/lib/libavcodec.a \
$_INST_/lib/libavutil.a \
$_INST_/lib/libsodium.a \
-lasound \
-lm \
-lpthread -lv4lconvert || exit 1

res2=$?

ldd toxblinkenwall
ls -hal toxblinkenwall
file toxblinkenwall

# --> toxblinkenwall
cp -av toxblinkenwall ~/work/deploy/
