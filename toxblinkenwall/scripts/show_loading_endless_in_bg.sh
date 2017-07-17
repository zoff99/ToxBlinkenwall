#! /bin/bash

function background
{

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/gfx/
delay=0.4
touchfile=~/ToxBlinkenwall/toxblinkenwall/_endless_loading_stop.txt

rm -f "$touchfile"

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


img_0="$gfx_dir""/""loading_bar_0.rgba"
img_1="$gfx_dir""/""loading_bar_25.rgba"
img_2="$gfx_dir""/""loading_bar_50.rgba"
img_3="$gfx_dir""/""loading_bar_75.rgba"
img_4="$gfx_dir""/""loading_bar_100.rgba"

cur=0
while [ true ]; do

	img=$(eval "echo \$img_${cur}")

	cat "$img" > "$fb_device"
	sleep "$delay"

	cur=$[ $cur + 1 ]
	if [ $cur -gt 4 ]; then
		cur=0
	fi

	if [ -e "$touchfile" ]; then
		cat /dev/zero > "$fb_device"
		exit
	fi
done

}

background &

