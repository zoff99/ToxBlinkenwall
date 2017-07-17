#! /bin/bash

##### -------------------------------------
export FB_WIDTH=640
export FB_HEIGHT=480
export BKWALL_WIDTH=192
export BKWALL_HEIGHT=144
stride_=$(cat /sys/class/graphics/fb0/stride)
bits_per_pixel_=$(cat /sys/class/graphics/fb0/bits_per_pixel)
virtual_size=$(cat /sys/class/graphics/fb0/virtual_size)
tmp1=$[ $bits_per_pixel_ / 8 ]
export real_width=$[ $stride_ / $tmp1 ]
##### -------------------------------------

##### -------------------------------------
# pick first available framebuffer device
# change for your needs here!
export fb_device=$(ls -1 /dev/fb*|tail -1)
##### -------------------------------------

##### --- only on the PI ---
sudo /etc/init.d/lightdm stop
##### --- only on the PI ---

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
