#### Install on the Blinkenwall


```
cd
git clone https://github.com/zoff99/ToxBlinkenwall
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

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/
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
-lrt $_INST_/lib/libopus.a \
-lvpx -lm $_INST_/lib/libsodium.a \
-lao -lpthread -lv4lconvert

echo 'default_driver=alsa
verbose=true
' > $_HOME_/.libao

# audio test program
gcc a.c -lao -ldl -lm -o a

cd $_HOME_
ln -s ToxBlinkenwall/toxblinkenwall/initscript.sh

echo 'IS_ON=BLINKENWALL
export IS_ON
' >> $_HOME_/.profile
```

#### Install on the RaspberryPI

it is the same procedure except the last command should be this:

```
echo 'IS_ON=RASPI
export IS_ON
' >> $_HOME_/.profile
```

and if you want 720p video resolution add:

```
HD=RASPIHD
export HD
' >> $_HOME_/.profile
```

if your screen turns off after 10 minutes do this:

```
sudo nano /etc/lightdm/lightdm.conf

# add to the [Seat:*] section
# xserver-command=X -s 0 dpms

# now save and reboot the pi!
```

