#! /bin/bash

qrcode_file_png=~/ToxBlinkenwall/toxblinkenwall/toxid.png
qrcode_file_rgba=~/ToxBlinkenwall/toxblinkenwall/toxid.rgba
toxidstr="$1"

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


rm -f "$qrcode_file_png"
rm -f "aa""$$"".png"
qrencode -t PNG -o "$qrcode_file_png" "$toxidstr"
convert "$qrcode_file_png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "aa""$$"".png"
rm -f "$qrcode_file_rgba"
convert "aa""$$"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba"
rm -f "aa""$$"".png"
