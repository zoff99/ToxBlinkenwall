#! /bin/bash



echo "starting ..."


## ----------------------
O_OPTIONS=" -O3 "
numcpus_=8
quiet_=1
## ----------------------


_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

export qqq=""

if [ "$quiet_""x" == "1x" ]; then
	export qqq=" -qq "
fi


redirect_cmd() {
    if [ "$quiet_""x" == "1x" ]; then
        "$@" > /dev/null 2>&1
    else
        "$@"
    fi
}


echo "installing system packages ..."

redirect_cmd apt-get update $qqq
# redirect_cmd apt-get install $qqq -y --force-yes lsb-release

echo "installing more system packages ..."

redirect_cmd apt-get install $qqq -y --force-yes \
    fontconfig-config \
    nano \
    libasound2 \
    git


# echo $_HOME_
cd $_HOME_
mkdir -p build

export _SRC_=$_HOME_/build/
export _INST_=$_HOME_/inst/

# echo $_SRC_
# echo $_INST_

mkdir -p $_SRC_
mkdir -p $_INST_

export PKG_CONFIG_PATH=$_INST_/lib/pkgconfig




echo "starting ToxBlinkenwall ..."

mkdir -p $_HOME_/rundir
cd $_HOME_/rundir

git clone https://github.com/zoff99/ToxBlinkenwall xx > /dev/null 2>&1
mv xx/* . > /dev/null 2>&1
mv xx/.??* . > /dev/null 2>&1
rm -Rf xx > /dev/null 2>&1

cd toxblinkenwall/


cp -av /artefacts/toxblinkenwall ./toxblinkenwall
chmod u+x toxblinkenwall *.sh

