#! /bin/bash


cd

export CF2=" -marm -march=armv8-a+crc -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -ftree-vectorize "
export CF3=" -funsafe-math-optimizations "
export VV1=" VERBOSE=1 V=1 "

export FULL=1
export ASAN=0

export _HOME_=$(pwd)
echo $_HOME_
cd $_HOME_/ToxBlinkenwall/toxblinkenwall/

./initscript.sh stop

cat /dev/zero > /dev/fb0
sleep 1

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/

mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/

if [ "$FULL""x" == "1x" ]; then

cd $_SRC_
git clone --depth=1 --branch=1.0.13 https://github.com/jedisct1/libsodium.git
cd libsodium
make clean
./autogen.sh
export CFLAGS=" $CF2 "
./configure --prefix=$_INST_ --disable-shared --disable-soname-versions # --enable-minimal
make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.7.0 https://github.com/webmproject/libvpx.git
cd libvpx
make clean
export CFLAGS=" $CF2 $CF3 "
export CXXLAGS=" $CF2 $CF3 "
./configure --prefix=$_INST_ --disable-examples \
--disable-unit-tests --enable-shared \
--size-limit=16384x16384 \
  --enable-postproc --enable-multi-res-encoding \
  --enable-temporal-denoising --enable-vp9-temporal-denoising \
  --enable-vp9-postproc
make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.2.1 https://github.com/xiph/opus.git
cd opus
make clean
./autogen.sh
export CFLAGS=" $CF2 $CF3 "
export CXXLAGS=" $CF2 $CF3 "
./configure --prefix=$_INST_ --disable-shared
make -j 4
make install

fi



cd $_SRC_
# git clone https://github.com/zoff99/c-toxcore
cd c-toxcore

# git checkout zoff99/_0.1.10_2017_runtime_val_changes
## ** ## git pull

# ./autogen.sh


make clean
export CFLAGS=" $CF2 -D_GNU_SOURCE -I$_INST_/include/ -O3 -g -fstack-protector-all "
export LDFLAGS=-L$_INST_/lib
#./configure \
#--prefix=$_INST_ \
#--disable-soname-versions --disable-testing --disable-shared
make -j 4 && make install
res=$?


if [ $res -eq 0 ]; then

cd $_HOME_/ToxBlinkenwall/toxblinkenwall/

_OO_=" -g -O3 "

if [ "$ASAN""x" == "1x" ]; then
	CF2="$CF2 -fsanitize=address"
	LL1="" # "-lasan" # "-static-libasan"
	_OO_=" -g -O2 "
fi

gcc $_OO_ \
$CF2 $CF3 \
$LL1 \
-fstack-protector-all \
-Wno-unused-variable \
-fPIC -export-dynamic -I$_INST_/include -o toxblinkenwall -lm \
toxblinkenwall.c openGL/esUtil.c openGL/esShader.c rb.c \
-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads \
-I/opt/vc/include/interface/vmcs_host/linux -lGLESv2 -lEGL \
-lbcm_host -L/opt/vc/lib \
-std=gnu99 \
-L$_INST_/lib \
$_INST_/lib/libtoxcore.a \
$_INST_/lib/libtoxav.a \
-lrt \
$_INST_/lib/libopus.a \
$_INST_/lib/libvpx.a \
$_INST_/lib/libsodium.a \
-lasound \
-lpthread -lv4lconvert

res2=$?

cd $_HOME_

	if [ $res2 -eq 0 ]; then
		$_HOME_/ToxBlinkenwall/toxblinkenwall/initscript.sh start
	else
		echo "ERROR !!"
		# cat /dev/urandom > /dev/fb0
		$_HOME_/fill_fb.sh "1 1 1 1 1"
	fi

else
	echo "ERROR !!"
	cat /dev/urandom > /dev/fb0
fi


rm -f $_HOME_/compile_me.txt

