#! /bin/bash

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/gfx/

. $(dirname "$0")/vars.sh

img_0="$gfx_dir""/""video_calling_001.rgba"
img_1="$gfx_dir""/""video_calling_002.rgba"
img_2="$gfx_dir""/""video_calling_003.rgba"
img_3="$gfx_dir""/""video_calling_004.rgba"

cur=$(( $RANDOM % 4 ))

img=$(eval "echo \$img_${cur}")
cat /dev/zero > "$fb_device"
cat "$img" > "$fb_device"
