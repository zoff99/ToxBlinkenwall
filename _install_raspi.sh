#! /bin/bash

sudo apt-get --yes --force-yes install git

cd
rm -Rf ToxBlinkenwall/.git # remove previous install
rm -Rf tmp/
git clone https://github.com/zoff99/ToxBlinkenwall tmp
mkdir -p ToxBlinkenwall/
cp -a tmp/*  ToxBlinkenwall/
cp -a tmp/.gitignore ToxBlinkenwall/
cp -a tmp/.git ToxBlinkenwall/
rm -Rf tmp/

cd
export _HOME_=$(pwd)
echo $_HOME_
cd $_HOME_/ToxBlinkenwall/toxblinkenwall/

# ------------- install packages -------------
sudo apt-get --yes --force-yes install libjpeg-dev libpng-dev imagemagick htop mc fbset cmake qrencode
sudo apt-get --yes --force-yes install libqrencode-dev vim nano wget git make
sudo apt-get --yes --force-yes install autotools-dev libtool bc libv4l-dev libv4lconvert0 v4l-conf v4l-utils
sudo apt-get --yes --force-yes install libopus-dev libvpx-dev pkg-config libjpeg-dev libpulse-dev libconfig-dev
sudo apt-get --yes --force-yes install automake checkinstall check yasm
sudo apt-get --yes --force-yes install libao-dev

sudo apt-get --yes --force-yes install imagemagick qrencode

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/

rm -Rf $_SRC_
rm -Rf $_INST_

mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/

cd $_SRC_
git clone --depth=1 --branch=1.0.13 https://github.com/jedisct1/libsodium.git
cd libsodium
./autogen.sh
./configure --prefix=$_INST_ --disable-shared --disable-soname-versions # --enable-minimal
make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.6.1 https://github.com/webmproject/libvpx.git
cd libvpx
./configure --prefix=$_INST_ --disable-examples --disable-unit-tests --enable-shared
make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.2.1 https://github.com/xiph/opus.git
cd opus
./autogen.sh
./configure --prefix=$_INST_ --disable-shared
make -j 4
make install

cd $_SRC_
# git clone https://github.com/TokTok/c-toxcore
git clone https://github.com/zoff99/c-toxcore
cd c-toxcore

# v0.1.10 cfg_dec2              3921fd04ee233a21befa960cf26214410e1b6582
# v0.1.10 cfg_dec               94bf0a32adac079b7739c6d32cfc0e504993f962
# v0.1.10 onlyKF                74dc53cf180e32f92ebb3cb5e8542e919cc3b343
# v0.1.10 tweaks3               25d1fce22ddc87089cf53e9b3c5bcf9d56a57374
# v0.1.10 mobtweaks             f73b345c21fae0e0e56fae86dc82f63188a00aca
# v0.1.10                       6295d28a1ec00d1caa03adce8fac6baf456ca7da
# v0.1.9                        a429ef4a28a5e5e0ad010efffb76d2abc3ada0af
# v0.1.8                        f6db9333e2d1262e7ba3846563c30f63c98ffa38
# v0.1.7                        48c86e942d487a8856cbd25797b320bfb1879ddc
# v0.1.6                        895de7ef26e7617769f2271345e414545c2581f8
# v0.1.5                        995578f1038842288c1ff552fd796ab2377db6e1
# v0.1.4                        27a97a8280813ec05a5209811c40ab23203bb292

git checkout 3921fd04ee233a21befa960cf26214410e1b6582

./autogen.sh

export CFLAGS=-I$_INST_/include/
export LDFLAGS=-L$_INST_/lib
./configure \
--prefix=$_INST_ \
--disable-soname-versions --disable-testing --disable-shared
make -j 4
make install


cd $_HOME_/ToxBlinkenwall/toxblinkenwall/

gcc -g -O3 -fPIC -export-dynamic -I$_INST_/include -o toxblinkenwall -lm toxblinkenwall.c \
-std=gnu99 \
-L$_INST_/lib \
$_INST_/lib/libtoxcore.a \
$_INST_/lib/libtoxav.a \
-lrt \
$_INST_/lib/libopus.a \
$_INST_/lib/libvpx.a \
-lm \
$_INST_/lib/libsodium.a \
-lao -lpthread -lv4lconvert

echo 'default_driver=alsa
verbose=true
' > $_HOME_/.libao

# audio test program
gcc a.c -lao -ldl -lm -o a

cd $_HOME_

