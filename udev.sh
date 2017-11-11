#! /bin/bash

####################################
#
#  create the script:
#  /etc/udev/rules.d/80-plug-usb-device.rules
#
# KERNEL=="sd*[!0-9]", ACTION=="add", SUBSYSTEMS=="usb", RUN+="/home/pi/ToxBlinkenwall/toxblinkenwall/udev.sh '%E{DEVNAME}'"
#
# as root
#
###################################

$(dirname "$0")/udev2.sh "$1"
