#! /bin/bash

#*********************************
#
# ToxBlinkenwall - udev script - part 1
# (C)Zoff in 2017 - 2019
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
#
# KERNEL=="pcmC[D0-9cp]*", DRIVERS=="usb", ACTION=="add", RUN+="/home/pi/ToxBlinkenwall/toxblinkenwall/udev.sh '%E{DEVNAME}'"
# KERNEL=="pcmC[D0-9cp]*", DRIVERS=="usb", ACTION=="remove", RUN+="/home/pi/ToxBlinkenwall/toxblinkenwall/udev.sh '%E{DEVNAME}'"
# as root
#
#
# systemctl restart systemd-udevd
# systemctl daemon-reload
#
#
###################################

$(dirname "$0")/detect_usb_audio.sh "$1" "$2" "$3" &
$(dirname "$0")/process_usb_drive.sh "$1" "$2" "$3" &

