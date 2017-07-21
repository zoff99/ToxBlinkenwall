#! /bin/bash

. $(dirname "$0")/vars.sh

##### --- remove cursor ---
printf 'setterm --cursor off > /dev/tty0\nexit\n' | sudo bash
printf 'setterm --cursor off > /dev/tty1\nexit\n' | sudo bash
##### --- remove cursor ---

##### --- setup framebuffer ---
export FB_WIDTH=640
export FB_HEIGHT=480
export BKWALL_WIDTH=192
export BKWALL_HEIGHT=144
fbset -s
fbset -fb "$fb_device" -xres ${FB_WIDTH} -yres ${FB_HEIGHT} -vxres ${FB_WIDTH} -vyres ${FB_HEIGHT} -depth 32
fbset -s
cat /dev/zero > "$fb_device"
##### --- setup framebuffer ---
