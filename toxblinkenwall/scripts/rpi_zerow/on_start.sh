#! /bin/bash

# turn green led off
echo 'default-on' | sudo tee --append /sys/class/leds/led0/trigger

# turn red led off
echo 'default-on' | sudo tee --append /sys/class/leds/led1/trigger

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


# draw text -----------------
font = ImageFont.load_default()
text="  ToxBlinkenwall:"
draw.text((x, top+8), text, font=font, fill=255)
text="  ---===>>> starting"
draw.text((x, top+16), text, font=font, fill=255)
disp.image(image)
disp.show()
# draw text -----------------


END
