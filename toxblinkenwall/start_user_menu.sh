#! /bin/bash

#*********************************
#
# ToxBlinkenwall - script
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

sleep 18 # wait for tbw to shutdown properly
sudo openvt -c 1 -fs -- su - pi bash -c /home/pi/ToxBlinkenwall/toxblinkenwall/scripts/user_menu.sh &
