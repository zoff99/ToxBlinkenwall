#! /bin/bash

#####################################################
# update toxcam binary from Circle CI (master branch)
#####################################################

cd $(dirname "$0")

pkill toxcam_static # will stop toxcam
cp -av toxcam_static toxcam_static__BACKUP
wget -O toxcam_static 'https://circleci.com/api/v1/project/zoff99/ToxCam/latest/artifacts/0/$CIRCLE_ARTIFACTS/RASPI/toxcam_static?filter=successful&branch=master'
chmod u+rwx toxcam_static

