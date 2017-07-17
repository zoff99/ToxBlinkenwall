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


function convert_img
{
	img="$1"
	convert "$gfx_dir""/""$img"".png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "$gfx_dir""/""$img""_x_"".png"
	convert "$gfx_dir""/""$img""_x_"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$gfx_dir""/""$img"".rgba"
}

convert_img "loading_bar_25"
convert_img "loading_bar_50"
convert_img "loading_bar_75"
convert_img "loading_bar_100"
