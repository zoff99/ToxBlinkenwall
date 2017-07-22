#! /bin/bash

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/gfx/

. $(dirname "$0")/vars.sh

function convert_img
{
	img="$1"
	convert "$gfx_dir""/""$img"".png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "$gfx_dir""/""$img""_x_"".png"
	convert "$gfx_dir""/""$img""_x_"".png" -channel rgba -alpha on -set colorspace RGB -separate -swap 0,2 -combine -define png:color-type=6 "$gfx_dir""/""$img""_y_"".png"
	convert "$gfx_dir""/""$img""_y_"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$gfx_dir""/""$img"".rgba"
	rm -f "$gfx_dir""/""$img""_x_"".png" "$gfx_dir""/""$img""_y_"".png"
}

convert_img "loading_bar_0"
convert_img "loading_bar_25"
convert_img "loading_bar_50"
convert_img "loading_bar_75"
convert_img "loading_bar_100"

convert_img "video_calling_001"
convert_img "video_calling_002"
convert_img "video_calling_003"
convert_img "video_calling_004"

convert_img "tox_bw_clients"
