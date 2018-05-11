#! /bin/bash

#*********************************
#
# ToxBlinkenwall - udev script - part 1
# (C)Zoff in 2017
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

####################################
#
#  create the script:
#  /etc/udev/rules.d/80-plug-usb-device.rules
#
# KERNEL=="sd*[!0-9]", ACTION=="add", RUN+="/home/pi/ToxBlinkenwall/toxblinkenwall/udev.sh '%E{DEVNAME}'"
# as root
#
###################################

$(dirname "$0")/udev2.sh "$1"
