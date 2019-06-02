#*********************************
#
# ToxBlinkenwall - stats script for OLED display on the Pi ZeroW
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

# Copyright (c) 2017 Adafruit Industries
# Author: Tony DiCola & James DeVito
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# This example is for use on (Linux) computers that are using CPython with
# Adafruit Blinka to support CircuitPython libraries. CircuitPython does
# not support PIL/pillow (python imaging library)!

import time
import os, sys
import subprocess

from board import SCL, SDA
import board
import busio
from digitalio import DigitalInOut, Direction, Pull
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


# Create the I2C interface.
i2c = busio.I2C(SCL, SDA)

# Create the SSD1306 OLED class.
# The first two parameters are the pixel width and pixel height.  Change these
# to the right size for your display!
disp = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c)

# Input pins:
button_A = DigitalInOut(board.D5)
button_A.direction = Direction.INPUT
button_A.pull = Pull.UP

button_B = DigitalInOut(board.D6)
button_B.direction = Direction.INPUT
button_B.pull = Pull.UP

button_L = DigitalInOut(board.D27)
button_L.direction = Direction.INPUT
button_L.pull = Pull.UP

button_R = DigitalInOut(board.D23)
button_R.direction = Direction.INPUT
button_R.pull = Pull.UP

button_U = DigitalInOut(board.D17)
button_U.direction = Direction.INPUT
button_U.pull = Pull.UP

button_D = DigitalInOut(board.D22)
button_D.direction = Direction.INPUT
button_D.pull = Pull.UP

button_C = DigitalInOut(board.D4)
button_C.direction = Direction.INPUT
button_C.pull = Pull.UP


# Clear display.
disp.fill(0)
disp.show()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))

# Get drawing object to draw on image.
draw = ImageDraw.Draw(image)

# Draw a black filled box to clear the image.
draw.rectangle((0, 0, width, height), outline=0, fill=0)

# Draw some shapes.
# First define some constants to allow easy resizing of shapes.
padding = -2
top = padding
bottom = height-padding
# Move left to right keeping track of the current x position for drawing shapes.
x = 0

fifo_path = './ext_keys.fifo'

try:
    os.mkfifo(fifo_path)
except Exception:
    pass


def measure_temp():
        temp = os.popen("vcgencmd measure_temp").readline()
        return (temp.replace("temp=","")).rstrip()

def send_event(txt):
    # print(txt)
    fifo_write = os.open(fifo_path, os.O_RDWR)
    os.write(fifo_write, txt.encode('UTF8'))
    os.close(fifo_write)


# Load default font.
font = ImageFont.load_default()

# Alternatively load a TTF font.  Make sure the .ttf font file is in the
# same directory as the python script!
# Some other nice fonts to try: http://www.dafont.com/bitmap.php
# font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 9)
# *does not work* font = ImageFont.truetype('/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf', 9)
# font = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf', 9)

toggle = 0
toggle_char = ["+","*"]
need_draw = 0
custom_image = 0

while True:

    # if button_A.value and button_B.value and button_C.value and button_U.value and button_L.value and button_R.value and button_D.value:
    if button_A.value and button_B.value and button_U.value and button_L.value and button_R.value and button_D.value:
        # Draw a black filled box to clear the image.
        draw.rectangle((0, 0, width, height), outline=0, fill=0)

        # Shell scripts for system monitoring from here:
        # https://unix.stackexchange.com/questions/119126/command-to-display-memory-usage-disk-usage-and-cpu-load
        cmd = "hostname -I | cut -d\' \' -f1"
        IP = subprocess.check_output(cmd, shell=True).decode("utf-8")
        # cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: \" $(NF-2)}' | sed -e 's#,$##'"
        cmd = "top -bn1 | head -1 | grep load |sed -e 's#^.*load average: ##'|cut -d\" \" -f1|sed -e 's#,$##'|awk '{ printf \"CPU Load: \" $0 }'"
        CPU = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%s MB\", $3,$2 }'"
        MemUsage = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "iwgetid -r 2>/dev/null"
        SSID = ""
        try:
            SSID = subprocess.check_output(cmd, shell=True).decode("utf-8")
        except:
            SSID = ""

        cmd = "cat /home/pi/ToxBlinkenwall/toxblinkenwall/db/ownname.txt 2>/dev/null"
        ownname = ""
        try:
            ownname = subprocess.check_output(cmd, shell=True).decode("utf-8")
        except:
            ownname = ""

        cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%d GB  %s\", $3,$2,$5}'"
        Disk = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "date '+%Y.%m.%d %H:%M:%S'"
        datetime_str = subprocess.check_output(cmd, shell=True).decode("utf-8")
        # cmd = "date '+%A'"
        # dayname_str = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "cat /home/pi/ToxBlinkenwall/toxblinkenwall/share/online_status.txt 2>/dev/null"
        online_status_str = ""
        try:
            online_status_str = subprocess.check_output(cmd, shell=True).decode("utf-8")
        except:
            online_status_str = ""

        toggle = 1 - toggle

        # Write four lines of text.
        draw.text((x, top+0), ""+ownname, font=font, fill=255)
        draw.text((x, top+9*1), "IP: "+IP, font=font, fill=255)
        draw.text((x, top+9*2), CPU, font=font, fill=255)
        draw.text((x, top+9*3), MemUsage, font=font, fill=255)
        draw.text((x, top+9*4), measure_temp() + "" + toggle_char[toggle]  + " " + SSID, font=font, fill=255)
        draw.text((x, top+9*5), datetime_str, font=font, fill=255)
        draw.text((x, top+9*6), online_status_str, font=font, fill=255)

        # Display image.
        disp.image(image)
        disp.show()

        # --foreground=FFFFFF --background=000000
        cmd = "qrencode -s2 -m1 -o toxid2.png $(cat toxid.txt)"
        subprocess.check_output(cmd, shell=True).decode("utf-8")

        # cmd = "convert toxid2.png -crop 106x106+8+8 toxid2.png ; convert toxid2.png -resize 64x64 toxid2.png"
        # subprocess.check_output(cmd, shell=True).decode("utf-8")

        cmd = "mogrify -extent 128x64 -gravity Center -background black toxid2.png"
        subprocess.check_output(cmd, shell=True).decode("utf-8")

    for xy in range(0, 20):

        need_draw = 0
        if not button_U.value:
            qrimage = Image.open('toxid2.png').convert('1')
            disp.image(qrimage)
            custom_image = 1
            need_draw = 1

        if not button_L.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(0, 30), (18, 21), (18, 41)], outline=255, fill=0)  #left
            draw.text((x, top+0), "VOL: -", font=font, fill=255)
            send_event("play-vol:down\n")
            vol_current = subprocess.check_output("./alsa_mixer_ctrl.sh 2", shell=True).decode("utf-8")
            draw.text((x, top+9*1), ""+vol_current, font=font, fill=255)
            need_draw = 1

        if not button_R.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(60, 30), (42, 21), (42, 41)], outline=255, fill=0) #right
            draw.text((x, top+0), "VOL: +", font=font, fill=255)
            send_event("play-vol:up\n")
            vol_current = subprocess.check_output("./alsa_mixer_ctrl.sh 2", shell=True).decode("utf-8")
            draw.text((x, top+9*1), ""+vol_current, font=font, fill=255)
            need_draw = 1

        if not button_D.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(30, 60), (40, 42), (20, 42)], outline=255, fill=0) #down
            draw.text((x, top+0), "END Call", font=font, fill=255)
            send_event("hangup:\n")
            need_draw = 1

        #if not button_C.value:
        #    if need_draw == 0:
        #        draw.rectangle((0, 0, width, height), outline=0, fill=0)
        #    draw.rectangle((20, 22, 40, 40), outline=255, fill=0) #center
        #    need_draw = 1

        if not button_A.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            #draw.text((x, top+0), "BT:", font=font, fill=255)
            #bt_mac = subprocess.check_output("./scripts/rpi_zerow/get_bt_connected_mac.sh", shell=True).decode("utf-8")
            #bt_name = "NO CONN"
            #if bt_mac in (None, '') or not bt_mac.strip():
            #    bt_name = "NO CONN"
            #else:
            #    bt_name = subprocess.check_output("./scripts/rpi_zerow/get_bt_connected_name.sh", shell=True).decode("utf-8")
            #draw.text((x, top+9*1), ""+bt_mac, font=font, fill=255)
            #draw.text((x, top+9*2), ""+bt_name, font=font, fill=255)
            #need_draw = 1

            cmd = "echo $(cat /home/pi/ToxBlinkenwall/toxblinkenwall/share/delay.txt)\" / \"$(cat /home/pi/ToxBlinkenwall/toxblinkenwall/share/rtt.txt) 2>/dev/null"

            menu2 = True
            while menu2 == True:
                cmd_str = ""
                try:
                    cmd_str = subprocess.check_output(cmd, shell=True).decode("utf-8")
                except:
                    cmd_str = ""

                draw.rectangle((0, 0, width, height), outline=0, fill=0)
                draw.text((x, top+0), "delay / RTT", font=font, fill=255)
                draw.text((x, top+9*1), ""+cmd_str, font=font, fill=255)
                disp.image(image)
                disp.show()
                time.sleep(0.3)

                if not button_D.value:
                    draw.rectangle((0, 0, width, height), outline=0, fill=0)
                    draw.text((x, top+0), "... back", font=font, fill=255)
                    disp.image(image)
                    disp.show()
                    need_draw = 1
                    menu2 = False
                    time.sleep(0.8)

        if not button_B.value:
            draw.rectangle((0, 0, width, height), outline=0, fill=0)
            disp.image(image)
            disp.show()

            p_book_num = 1
            menu1 = True
            while menu1 == True:
                if not button_R.value:
                    if p_book_num < 9:
                        p_book_num = p_book_num + 1
                    else:
                        p_book_num = 1

                draw.rectangle((0, 0, width, height), outline=0, fill=0)
                draw.text((x, top+0), "CALL: ?", font=font, fill=255)
                draw.text((x, top+9*1), "P-"+ str(p_book_num), font=font, fill=255)
                p_book_name = subprocess.check_output("cat ./db/book_name_"+str(p_book_num)+".txt 2>/dev/null||echo \"\"", shell=True).decode("utf-8")
                draw.text((x, top+9*2), ""+ p_book_name, font=font, fill=255)
                disp.image(image)
                disp.show()

                if not button_D.value:
                    draw.rectangle((0, 0, width, height), outline=0, fill=0)
                    draw.polygon([(30, 60), (40, 42), (20, 42)], outline=255, fill=0) #down (call number)
                    draw.text((x, top+0), "Calling:", font=font, fill=255)
                    draw.text((x, top+9*1), "P-"+ str(p_book_num), font=font, fill=255)
                    draw.text((x, top+9*2), ""+ p_book_name, font=font, fill=255)
                    disp.image(image)
                    disp.show()
                    send_event("call:"+str(p_book_num)+"\n")
                    need_draw = 1
                    menu1 = False
                    time.sleep(0.8)

                if not button_A.value:
                    draw.rectangle((0, 0, width, height), outline=0, fill=0)
                    draw.text((x, top+0), "... not calling", font=font, fill=255)
                    disp.image(image)
                    disp.show()
                    need_draw = 1
                    menu1 = False
                    time.sleep(0.8)

                time.sleep(0.1)


        if need_draw == 1:
            if custom_image == 0:
                disp.image(image)
            disp.show()
            custom_image = 0
            need_draw = 0

        time.sleep(0.5)

