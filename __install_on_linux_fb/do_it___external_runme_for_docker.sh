#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_

# docker info

mkdir -p $_HOME_/artefacts
mkdir -p $_HOME_/script
cat "$_HOME_"/do_it___external.sh > $_HOME_/script/do_it___external.sh
chmod a+rx $_HOME_/script/do_it___external.sh


i="debian:9"

echo "building for $i ..."
system_to_build_for="$i"

cd $_HOME_/
docker run -ti --rm \
  -v $_HOME_/artefacts:/artefacts \
  -v $_HOME_/script:/script \
  -e DISPLAY=$DISPLAY \
  --net=host \
  -v "$HOME/.Xauthority:/root/.Xauthority:rw" \
  "$system_to_build_for" \
  /bin/bash /script/do_it___external.sh

cd $_HOME_/
echo "... READY."

