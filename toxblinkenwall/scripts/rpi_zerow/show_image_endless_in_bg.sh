#! /bin/bash

function show_incoming_text
{

python3 - <<END


import time
import os
import subprocess

from board import SCL, SDA
import busio
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


i2c = busio.I2C(SCL, SDA)

disp = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c)

# Clear display.
disp.fill(0)
disp.show()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))
draw = ImageDraw.Draw(image)
draw.rectangle((0, 0, width, height), outline=0, fill=0)
padding = -2
top = padding
bottom = height-padding
x = 0

font = ImageFont.load_default()
draw.rectangle((0, 0, width, height), outline=0, fill=0)

draw.text((x, top+(8*3)), "===================", font=font, fill=255)
draw.text((x, top+(8*4)), "incoming image ...", font=font, fill=255)
draw.text((x, top+(8*5)), "===================", font=font, fill=255)


# display text for 1 seconds
for x in range(0, 40):
    disp.image(image)
    disp.show()
    time.sleep(0.5)

    if os.path.isfile('/tmp/incoming_image_text.txt'):
        break

END


}

function background
{

$(dirname "$0")/stop_image_endless.sh
sleep 0.5

gfx_dir=$(dirname "$0")/../tmp/
touchfile=$(dirname "$0")/../_endless_image_stop.txt
img="$1"

rm -f "$touchfile"


. $(dirname "$0")/vars.sh


if [ ! -e "$img" ]; then
    # file does not exist
	rm -f "$img"
	rm -f "$gfx_dir"/_anim/*
	rm -Rf "$gfx_dir"/_anim/
    touch /tmp/incoming_image_text.txt
	exit
fi

filesize=$(stat -c '%s' "$img" 2>/dev/null)

# file size max ~10MB
if [ $filesize -gt 10000000 ]; then
    # file too large
	rm -f "$img"
	rm -f "$gfx_dir"/_anim/*
	rm -Rf "$gfx_dir"/_anim/
    touch /tmp/incoming_image_text.txt
	exit
fi


identify "$img"
err_=$?

if [ $err_ -eq 1 ]; then
	# error not an known image format
	rm -f "$img"
	rm -f "$gfx_dir"/_anim/*
	rm -Rf "$gfx_dir"/_anim/
    touch /tmp/incoming_image_text.txt
	exit
fi

frame_count=$(identify -format %n "$img")
if [ "$frame_count""x" != "1x" ]; then
	# animations not supported
	rm -f "$img"
	rm -f "$gfx_dir"/_anim/*
	rm -Rf "$gfx_dir"/_anim/
    touch /tmp/incoming_image_text.txt
    exit
else # single frame image
    mkdir -p "$gfx_dir"/_anim/
    rm -f "$gfx_dir"/_anim/*
    cur_frame=0
    convert "$img" -resize 128x64 "$gfx_dir"/_anim/animframe.2.0.png
    mogrify -extent 128x64 -gravity Center -background black "$gfx_dir"/_anim/animframe.2.0.png
    touch /tmp/incoming_image_text.txt
    export IMG_FILE_NAME="$gfx_dir"/_anim/animframe.2.0.png
fi


python3 - <<END


import time
import os
import subprocess

from board import SCL, SDA
import busio
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


i2c = busio.I2C(SCL, SDA)

disp = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c)

# Clear display.
disp.fill(0)
disp.show()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
# print("w="+str(width)+" h="+str(height))

img_filename=os.environ.get('IMG_FILE_NAME')
custom_image = Image.open(img_filename).convert('1')

disp.image(custom_image)


# display image for 5 seconds
for x in range(0, 9):
    disp.image(custom_image)
    disp.show()
    time.sleep(0.5)

END

rm -f "$img"
rm -f "$gfx_dir"/_anim/*
rm -Rf "$gfx_dir"/_anim/
rm -f /tmp/incoming_image_text.txt

}

rm -f /tmp/incoming_image_text.txt

show_incoming_text &
background "$1" &
