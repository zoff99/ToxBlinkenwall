#! /bin/bash

#*********************************
#
# ToxBlinkenwall - udev script - part 1
# (C)Zoff in 2017
#
# https://github.com/zoff99/ToxBlinkenwall
#
# in this file: /lib/systemd/system/systemd-udevd.service
# comment out these lines, or the script will fail mostly:
#
# KillMode=mixed
# WatchdogSec=3min
# TasksMax=infinity
# MountFlags=slave
# MemoryDenyWriteExecute=yes
# RestrictRealtime=yes
# RestrictAddressFamilies=AF_UNIX AF_NETLINK AF_INET AF_INET6
#
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

$(dirname "$0")/udev2.sh "$1" &


