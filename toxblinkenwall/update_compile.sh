#! /bin/bash

pushd ~
export _INST_="$(pwd)""/inst/"
popd

gcc -g -O3 -fPIC -export-dynamic -I$_INST_/include -o toxblinkenwall -lm toxblinkenwall.c \
-std=gnu99 \
-L$_INST_/lib \
$_INST_/lib/libtoxcore.a \
$_INST_/lib/libtoxav.a \
-lrt $_INST_/lib/libopus.a \
-lvpx -lm $_INST_/lib/libsodium.a \
/usr/lib/arm-linux-gnueabihf/libportaudio.a \
-lao -lpthread -lv4lconvert
