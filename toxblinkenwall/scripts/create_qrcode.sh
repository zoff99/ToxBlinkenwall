#! /bin/bash

function background
{

qrcode_file_png=~/ToxBlinkenwall/toxblinkenwall/toxid.png
qrcode_file_rgba=~/ToxBlinkenwall/toxblinkenwall/toxid.rgba
qrcode_touchfile_ready=~/ToxBlinkenwall/toxblinkenwall/toxid_ready.txt
toxidstr="$1"

. $(dirname "$0")/vars.sh

rm -f "$qrcode_file_png"
rm -f "aa""$$"".png"
qrencode -t PNG -o "$qrcode_file_png" "$toxidstr"
convert "$qrcode_file_png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "aa""$$"".png"
rm -f "$qrcode_file_rgba"
convert "aa""$$"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba"
rm -f "aa""$$"".png"

touch "$qrcode_touchfile_ready"

}

background "$1" &

