#! /bin/bash

#*********************************
#
# ToxBlinkenwall
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

fifo="../ext_keys.fifo"

while [ true ]; do
	cat "$fifo"
done
