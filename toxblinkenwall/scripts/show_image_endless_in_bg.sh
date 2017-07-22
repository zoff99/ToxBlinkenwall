#! /bin/bash

function background
{

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/tmp/
touchfile=~/ToxBlinkenwall/toxblinkenwall/_endless_image_stop.txt
img="$1"

rm -f "$touchfile"

. $(dirname "$0")/vars.sh

while [ true ]; do

	frame_count=$(identify -format %n "$img")
	if [ "$frame_count""x" != "1x" ]; then
			mkdir -p "$gfx_dir"/_anim/
			rm -f "$gfx_dir"/_anim/*
			convert -coalesce "$img" "$gfx_dir"/_anim/animframe.%d.png
			# identify -verbose -format "%s:%T\n" "$img" # frame:delay

			delayArr=($(convert "$img" -format "%T\n" info:))
			numframes=${#delayArr[*]}

			# get real delay ----
			frames_=true
			cur_frame=0
			while [ $frames_ ]; do
					# echo "$cur_frame"":"

					# convert for use in framebuffer -----------------
					convert "$gfx_dir"/_anim/animframe."$cur_frame".png -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "$gfx_dir"/_anim/animframe.2."$cur_frame".png
					convert "$gfx_dir"/_anim/animframe.2."$cur_frame".png -channel rgba -alpha on -set colorspace RGB -separate -swap 0,2 -combine -define png:color-type=6 "$gfx_dir"/_anim/animframe.3."$cur_frame".png
					# ------------- swap B and R channels -------------
					convert "$gfx_dir"/_anim/animframe.3."$cur_frame".png -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$gfx_dir"/_anim/animframe."$cur_frame".rgba
					rm -f "$gfx_dir"/_anim/animframe.2."$cur_frame".png "$gfx_dir"/_anim/animframe.3."$cur_frame".png
					# convert for use in framebuffer -----------------

					# echo ${delayArr[$cur_frame]}
					delayArr[$cur_frame]=$(printf "scale=3\n${delayArr[$cur_frame]} / 100 \n"|bc)
					# echo ${delayArr[$cur_frame]}
					cur_frame=$[ $cur_frame + 1 ]
					if [ "$cur_frame""x" == "$numframes""x" ]; then
							break
					fi
			done
			# get real delay ----

			# play loop ----
			while [ true ]; do
					frames_=true
					cur_frame=0
					while [ $frames_ ]; do
							# echo ${delayArr[$cur_frame]}
							# show frame
							sleep ${delayArr[$cur_frame]}

							cat "$gfx_dir"/_anim/animframe."$cur_frame".rgba > "$fb_device"

							cur_frame=$[ $cur_frame + 1 ]
							if [ "$cur_frame""x" == "$numframes""x" ]; then
									break
							fi

							if [ -e "$touchfile" ]; then
								# cleanup
								rm -f "$gfx_dir"/_anim/*
								rm -Rf "$gfx_dir"/_anim/
								rm -f "$img"
								cat /dev/zero > "$fb_device"
								exit
							fi

					done

					if [ -e "$touchfile" ]; then
						# cleanup
						rm -f "$gfx_dir"/_anim/*
						rm -Rf "$gfx_dir"/_anim/
						rm -f "$img"
						cat /dev/zero > "$fb_device"
						exit
					fi

			done
			# get real delay ----

	else # single frame image
			cat "$img" > "$fb_device"
			rm -f "$img"
			exit
	fi
done

}

background "$1" &

