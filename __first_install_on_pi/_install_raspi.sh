#! /bin/bash

sudo apt-get update
sudo apt-get --yes --force-yes install git


# totally disable swap ---------------
sudo service dphys-swapfile stop
sudo systemctl disable dphys-swapfile
sudo apt-get --yes --force-yes purge dphys-swapfile
# totally disable swap ---------------

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

chmod u+x ./initscript.sh
./initscript.sh stop
cat /dev/zero > /dev/fb0
sleep 1


# ------------- install packages -------------
sudo apt-get --yes --force-yes install libjpeg-dev libpng-dev imagemagick htop mc fbset cmake qrencode
sudo apt-get --yes --force-yes install libqrencode-dev vim nano wget git make
sudo apt-get --yes --force-yes install autotools-dev libtool bc libv4l-dev libv4lconvert0 v4l-conf v4l-utils
sudo apt-get --yes --force-yes install pkg-config libjpeg-dev libpulse-dev libconfig-dev
sudo apt-get --yes --force-yes install automake checkinstall check yasm
sudo apt-get --yes --force-yes install libao-dev libasound2-dev


export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/

export CF2=" -O3 -g -marm -march=armv8-a+crc -mtune=cortex-a53 -mfpu=neon-fp-armv8 \
 -mfloat-abi=hard -ftree-vectorize "
export CF3=" -funsafe-math-optimizations "
export VV1=" VERBOSE=1 V=1 "


rm -Rf $_SRC_
rm -Rf $_INST_

mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/
export PKG_CONFIG_PATH=$_INST_/lib/pkgconfig




cd $_SRC_
rm -Rf libav
# git clone https://github.com/libav/libav
git clone https://github.com/FFmpeg/FFmpeg libav
cd libav
# git checkout v12.3
# git checkout n3.3.9
git checkout n4.1
./configure --prefix=$_INST_ --disable-devices --disable-programs \
--disable-doc --disable-avdevice --disable-avformat \
--disable-swscale \
--disable-avfilter --disable-network --disable-everything \
--disable-bzlib \
--disable-libxcb-shm \
--disable-libxcb-xfixes \
--enable-parser=h264 \
--enable-runtime-cpudetect \
--enable-mmal \
--enable-decoder=h264_mmal \
--enable-gpl --enable-decoder=h264
make clean
make -j4
make install




cd $_SRC_
# rm -Rf x264
git clone git://git.videolan.org/x264.git
cd x264
git checkout 0a84d986e7020f8344f00752e3600b9769cc1e85 # stable
./configure --prefix=$_INST_ --disable-opencl --enable-shared --enable-static \
--disable-avs --disable-cli
make clean
make -j4
make install


cd $_SRC_
git clone --depth=1 --branch=1.0.16 https://github.com/jedisct1/libsodium.git
cd libsodium
./autogen.sh
export CFLAGS=" $CF2 "
./configure --prefix=$_INST_ --disable-shared --disable-soname-versions
make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.7.0 https://github.com/webmproject/libvpx.git
cd libvpx
make clean
export CFLAGS=" $CF2 $CF3 "
export CXXFLAGS=" $CF2 $CF3 "
./configure --prefix=$_INST_ --disable-examples \
  --disable-unit-tests --enable-shared \
  --size-limit=16384x16384 \
  --enable-onthefly-bitpacking \
  --enable-error-concealment \
  --enable-runtime-cpu-detect \
  --enable-multi-res-encoding \
  --enable-postproc \
  --enable-vp9-postproc \
  --enable-temporal-denoising \
  --enable-vp9-temporal-denoising

#  --enable-better-hw-compatibility \

make -j 4
make install

cd $_SRC_
git clone --depth=1 --branch=v1.3-rc https://github.com/xiph/opus.git
cd opus
./autogen.sh
export CFLAGS=" $CF2 $CF3 "
export CXXFLAGS=" $CF2 $CF3 "
./configure --prefix=$_INST_ --disable-shared
make -j 4
make install

cd $_SRC_
# git clone https://github.com/TokTok/c-toxcore
git clone https://github.com/Zoxcore/c-toxcore
cd c-toxcore

git checkout "toxav-multi-codec"

./autogen.sh
make clean
export CFLAGS=" $CF2 -D_GNU_SOURCE -I$_INST_/include/ -O3 -g -fstack-protector-all "
export LDFLAGS=-L$_INST_/lib

./configure \
--prefix=$_INST_ \
--disable-soname-versions --disable-testing --disable-shared
make -j 4
make install


cd $_HOME_/ToxBlinkenwall/toxblinkenwall/



gcc \
-DRASPBERRY_PI -DOMX_SKIP64BIT -DUSE_VCHIQ_ARM \
-I/opt/vc/include -I/opt/vc/interface/vmcs_host/linux -I/opt/vc/interface/vcos/pthreads \
$CF2 $CF3 \
-fstack-protector-all \
-Wno-unused-variable \
-fPIC -export-dynamic -I$_INST_/include -o toxblinkenwall -lm \
toxblinkenwall.c openGL/esUtil.c openGL/esShader.c rb.c \
-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads \
-I/opt/vc/include/interface/vmcs_host/linux -lbrcmEGL -lbrcmGLESv2 \
-lbcm_host -L/opt/vc/lib \
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
-lpthread -lv4lconvert \
-lmmal -lmmal_core -lmmal_vc_client -lmmal_components -lmmal_util \
-L/opt/vc/lib -lbcm_host -lvcos -lopenmaxil

res2=$?




cd $_HOME_

if [ $res2 -eq 0 ]; then
    echo "compile: OK"
    
    if [ ! -e ~/.tbw_install.ready ]; then
        echo "initial config ..."
        echo '
IS_ON=RASPI
HD=RASPIHD
export IS_ON
export HD

' >> ~/.profile

        alsa_0_cfg="/usr/share/alsa/alsa_0.conf"
        alsa_1_cfg="/usr/share/alsa/alsa_1.conf"
        alsa_template="$_HOME_/ToxBlinkenwall/__first_install_on_pi/alsa_template.txt"

        cat "$alsa_template" | sed -e "s#@@USBCARD@@#""$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq |grep 'U0')""#" > /tmp/alsa_tmp.txt

        sudo cp -av "/usr/share/alsa/alsa.conf" "$alsa_0_cfg"
        sudo cp -av "/usr/share/alsa/alsa.conf" "$alsa_1_cfg"
        cat /tmp/alsa_tmp.txt | sudo tee -a "$alsa_0_cfg"

        cat /tmp/alsa_tmp.txt | sed -e 's#slave.pcm "card_bcm"#slave.pcm "usb"#' > /tmp/alsa_tmp2.txt

        cat /tmp/alsa_tmp2.txt | sudo tee -a "$alsa_1_cfg"
        sudo cp -av "$alsa_0_cfg" "/usr/share/alsa/alsa.conf"

        rm -f /tmp/alsa_tmp.txt
        rm -f /tmp/alsa_tmp2.txt

        sudo cp -av /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.BACKUP
        sudo sed -i -e 's#^.*<policy domain="path".*$#<!-- removed by ToxBlinkenwall -->#g' /etc/ImageMagick-6/policy.xml

        touch ~/.tbw_install.ready
        echo "... READY"
    fi


    . ~/.profile
    $_HOME_/ToxBlinkenwall/toxblinkenwall/initscript.sh start
else
    echo "ERROR !!"
fi


