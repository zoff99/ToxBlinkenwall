
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

cmd = "hostname -I | cut -d\' \' -f1"
IP = subprocess.check_output(cmd, shell=True).decode("utf-8")

draw.text((x, top+8), "IP: "+IP, font=font, fill=255)
draw.text((x, top+0), "  +* booting *+", font=font, fill=255)

disp.image(image)
disp.show()
