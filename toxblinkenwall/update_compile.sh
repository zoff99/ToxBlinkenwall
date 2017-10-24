#! /bin/bash

pushd ~
export _INST_="$(pwd)""/inst/"
popd


gcc -g -O3 -fPIC -export-dynamic -I$_INST_/include \
-o toxblinkenwall \
toxblinkenwall.c \
ringbuf.c \
-std=gnu99 \
-L$_INST_/lib \
$_INST_/lib/libtoxcore.a \
$_INST_/lib/libtoxav.a \
$_INST_/lib/libopus.a \
$_INST_/lib/libsodium.a \
$_INST_/lib/libvpx.a \
-lrt \
-lm \
-lao \
-lpthread \
-lv4lconvert
