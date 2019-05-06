#! /bin/bash

. $(dirname "$0")/vars.sh

##### --- remove cursor ---
if [ "$IS_ON""x" == "RASPI""x" ]; then
  printf 'setterm --cursor off > /dev/tty0\nexit\n' | sudo bash
  printf 'setterm --cursor off > /dev/tty1\nexit\n' | sudo bash
fi
##### --- remove cursor ---

##### --- setup framebuffer ---
fbset -s
fbset -fb "$fb_device" -xres ${FB_WIDTH} -yres ${FB_HEIGHT} -vxres ${FB_WIDTH} -vyres ${FB_HEIGHT} -depth 32
fbset -s
cat /dev/zero > "$fb_device"
##### --- setup framebuffer ---

python3 - <<END

import time
import os
import subprocess

from board import SCL, SDA
import busio
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


# Create the I2C interface.
i2c = busio.I2C(SCL, SDA)

# Create the SSD1306 OLED class.
# The first two parameters are the pixel width and pixel height.  Change these
# to the right size for your display!
disp = adafruit_ssd1306.SSD1306_I2C(128, 32, i2c)

# Clear display.
disp.fill(0)
disp.show()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))

padding = -2
top = padding
bottom = height-padding
x = 0

# Get drawing object to draw on image.
draw = ImageDraw.Draw(image)

# Draw a black filled box to clear the image.
draw.rectangle((0, 0, width, height), outline=0, fill=0)

disp.image(image)
disp.show()


END
