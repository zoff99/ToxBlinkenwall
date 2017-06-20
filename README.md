# ToxCam

Build Status
=
**CircleCI:** [![CircleCI](https://circleci.com/gh/zoff99/ToxCam/tree/master.png?style=badge)](https://circleci.com/gh/zoff99/ToxCam)
**Travis:** [![Build Status](https://travis-ci.org/zoff99/ToxCam.png?branch=master)](https://travis-ci.org/zoff99/ToxCam)


Development Snapshot Version (Linux)
=
the latest Development Snapshot can be downloaded from CircleCI, [here](https://circleci.com/api/v1/project/zoff99/ToxCam/latest/artifacts/0/$CIRCLE_ARTIFACTS/ubuntu_14_04_binaries/toxcam_static?filter=successful&branch=master)

Development Snapshot Version (Raspberry PI)
=
the latest Development Snapshot can be downloaded from CircleCI, [here](https://circleci.com/api/v1/project/zoff99/ToxCam/latest/artifacts/0/$CIRCLE_ARTIFACTS/RASPI/toxcam_static?filter=successful&branch=master)

install on PI
=

```
# as user pi:
git clone https://github.com/zoff99/ToxCam
cd ToxCam/toxcam
chmod u+rwx loop_services.sh update_from_ci.sh scripts/*.sh
./update_from_ci.sh
```
```
sudo apt-get install luvcview
sudo sed -i -e "s#exit 0#su - pi bash -c '/home/pi/ToxCam/toxcam/loop_services.sh' > /dev/null 2>/dev/null \&\nexit 0#" /etc/rc.local
```

then reboot
now ToxCam should be active already. get the ToxID

```
cat /home/pi/ToxCam/toxcam/toxcam.log|grep MyToxID|cut -d: -f3
```

note down the ToxID of your ToxCam and add it as friend from another ToxClient.

