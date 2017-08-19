#! /bin/bash
gcc -O2 -fPIC -export-dynamic \
-I~/inst/include -o toxblinkenwall -lm toxblinkenwall.c -std=gnu99 \
-L~/inst/lib ~/inst/lib/libtoxcore.a ~/inst/lib/libtoxav.a \
-lrt ~/inst/lib/libopus.a -lvpx -lm ~/inst/lib/libsodium.a \
-lao -lpthread -lv4lconvert