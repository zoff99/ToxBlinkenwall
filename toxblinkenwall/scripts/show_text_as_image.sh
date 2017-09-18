#! /bin/bash

function background2
{
	file_with_text=~/ToxBlinkenwall/toxblinkenwall/tmp/text.dat

	. $(dirname "$0")/vars.sh
	$(dirname "$0")/stop_image_endless.sh

	# mv "$file_with_text" /tmp/toxmessage.txt

	# openGL text stuff ------
	cat "$file_with_text" | node /usr/local/blinkenwall/poetry/poetry.js
	# openGL text stuff ------
}


function background
{

# set -x

gfx_dir=~/ToxBlinkenwall/toxblinkenwall/texttmp/
file_with_text=~/ToxBlinkenwall/toxblinkenwall/tmp/text.dat
font_=' -font DejaVu-Sans-Oblique '
split_long_words_and_lines_at=26
cut_at_lines=12

. $(dirname "$0")/vars.sh

$(dirname "$0")/stop_image_endless.sh
sleep 3
$(dirname "$0")/show_loading_endless_in_bg.sh

mkdir -p "$gfx_dir"
rm -f "$gfx_dir"/*


# convert for use in framebuffer -----------------
cur_frame=0

# echo '' >> "$file_with_text"

# rm -f "$file_with_text""_tmp"
# cat "$file_with_text" | fold -w "$split_long_words_and_lines_at" -s | head -"$cut_at_lines" > "$file_with_text""_tmp"
# cat "$file_with_text" | head -"$cut_at_lines" > "$file_with_text""_tmp"
# mv "$file_with_text""_tmp" "$file_with_text"

# ls -al "$file_with_text" >> /tmp/aa.txt
# cat "$file_with_text" >> /tmp/aa.txt

convert -background black -fill blue ${font_} \
	-size "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" \
	-gravity Center caption:@"$file_with_text" "$gfx_dir"/caption.png

convert "$gfx_dir"/caption.png -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "$gfx_dir"/animframe.2."$cur_frame".png
convert "$gfx_dir"/animframe.2."$cur_frame".png -channel rgba -alpha on -set colorspace RGB -separate -swap 0,2 -combine -define png:color-type=6 "$gfx_dir"/animframe.3."$cur_frame".png
# ------------- swap B and R channels -------------
convert "$gfx_dir"/animframe.3."$cur_frame".png -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$gfx_dir"/animframe."$cur_frame".rgba
rm -f "$gfx_dir"/animframe.2."$cur_frame".png "$gfx_dir"/animframe.3."$cur_frame".png
# convert for use in framebuffer -----------------

$(dirname "$0")/stop_loading_endless.sh
sleep 1


cat "$gfx_dir"/animframe."$cur_frame".rgba > "$fb_device"
rm -f "$gfx_dir"/caption.png
rm -f "$gfx_dir"/*
rm -f "$file_with_text""_tmp"
rm -f "$file_with_text"

}


if [ "$IS_ON""x" == "RASPI""x" ]; then
	background &
else
	background2 &
fi
