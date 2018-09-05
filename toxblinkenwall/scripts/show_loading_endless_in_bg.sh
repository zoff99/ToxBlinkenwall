#! /bin/bash

function background
{

gfx_dir=$(dirname "$0")/../gfx/
delay=0.4
touchfile=$(dirname "$0")/../_endless_loading_stop.txt

rm -f "$touchfile"

. $(dirname "$0")/vars.sh

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

