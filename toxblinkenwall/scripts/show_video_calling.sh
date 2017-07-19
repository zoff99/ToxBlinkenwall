#! /bin/bash

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/gfx/

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


img_0="$gfx_dir""/""video_calling_001.rgba"
img_1="$gfx_dir""/""video_calling_002.rgba"
img_2="$gfx_dir""/""video_calling_003.rgba"
img_3="$gfx_dir""/""video_calling_004.rgba"

cur=$(( $RANDOM % 4 ))

img=$(eval "echo \$img_${cur}")
cat /dev/zero > "$fb_device"
cat "$img" > "$fb_device"
