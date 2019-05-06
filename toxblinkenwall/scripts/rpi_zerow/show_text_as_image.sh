#! /bin/bash

gfx_dir=$(dirname "$0")/../texttmp/
export file_with_text=$(dirname "$0")/../tmp/text.dat

. $(dirname "$0")/vars.sh
$(dirname "$0")/stop_image_endless.sh


python3 - <<END


import time
import os
import subprocess

from board import SCL, SDA
import busio
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


i2c = busio.I2C(SCL, SDA)

disp = adafruit_ssd1306.SSD1306_I2C(128, 32, i2c)

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

cmd = "hostname -I | cut -d\' \' -f1"
IP = subprocess.check_output(cmd, shell=True).decode("utf-8")

filename=os.environ.get('file_with_text')

if (filename == None):
    exit(-1)

txt = open(filename, 'r')
text_in_file=txt.read()

draw.text((x, top+0), text_in_file[0:17], font=font, fill=255)
draw.text((x, top+8), text_in_file[(0+(1*17)):(17+(1*17))], font=font, fill=255)
draw.text((x, top+16), text_in_file[(0+(2*17)):(17+(2*17))], font=font, fill=255)
draw.text((x, top+25), text_in_file[(0+(3*17)):(17+(3*17))], font=font, fill=255)

txt.close()


# display test for 3 seconds
for x in range(0, 5):
    disp.image(image)
    disp.show()
    time.sleep(0.5)



END

rm -f "$file_with_text"
