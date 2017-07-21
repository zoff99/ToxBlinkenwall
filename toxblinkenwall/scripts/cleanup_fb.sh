#! /bin/bash

. $(dirname "$0")/vars.sh

##### --- remove cursor ---
if [ "$IS_ON""x" == "RASPI""x" ]; then
  printf 'setterm --cursor off > /dev/tty0\nexit\n' | sudo bash
  printf 'setterm --cursor off > /dev/tty1\nexit\n' | sudo bash
fi
##### --- remove cursor ---

##### --- setup framebuffer ---
fbset -s
fbset -fb "$fb_device" -xres ${FB_WIDTH} -yres ${FB_HEIGHT} -vxres ${FB_WIDTH} -vyres ${FB_HEIGHT} -depth 32
fbset -s
cat /dev/zero > "$fb_device"
##### --- setup framebuffer ---
