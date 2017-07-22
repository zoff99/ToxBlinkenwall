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

							cat "$img" > "$fb_device"

							cur_frame=$[ $cur_frame + 1 ]
							if [ "$cur_frame""x" == "$numframes""x" ]; then
									break
							fi

							if [ -e "$touchfile" ]; then
								# cleanup
								rm -f "$gfx_dir"/_anim/*
								rm -Rf "$gfx_dir"/_anim/
								cat /dev/zero > "$fb_device"
								exit
							fi

					done

					if [ -e "$touchfile" ]; then
						# cleanup
						rm -f "$gfx_dir"/_anim/*
						rm -Rf "$gfx_dir"/_anim/
						cat /dev/zero > "$fb_device"
						exit
					fi

			done
			# get real delay ----

	else # single frame image
			cat "$img" > "$fb_device"
			exit
	fi
done

}

background &

