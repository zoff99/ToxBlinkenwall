#! /usr/bin/env python

#*********************************
#
# ToxBlinkenwall - keypad script
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

import RPi.GPIO as GPIO
from time import sleep     # this lets us have a time delay (see line 15)
GPIO.setmode(GPIO.BCM)     # set up BCM GPIO numbering

import time
import os
last_button_press = 0
button_press_min_delay_ms = 400 # 400ms until you can register the same button press again

# What Raspberry Pi revision are we running?
GPIO.RPI_REVISION    #  0 = Compute Module, 1 = Rev 1, 2 = Rev 2, 3 = Model B+

# What version of RPi.GPIO are we running?
GPIO.VERSION

fifo_path = '../ext_keys.fifo'
cur_button = -1

# Custom ToxPhone1 values -----
# ROW    = [4, -1, -1, 17]
# COLUMN = [27, 18, 22, -1]
# Custom ToxPhone1 values -----

ROW    = [16, 20, 21, 5] # these are the GPIO numbers, NOT the real PIN numbers
COLUMN = [6, 13, 19, 26]

# Set all columns as output low
for j in range(len(COLUMN)):
    if COLUMN[j] != -1:
        GPIO.setup(COLUMN[j], GPIO.OUT)
        GPIO.output(COLUMN[j], GPIO.LOW)
 
# Set all rows as input
for i in range(len(ROW)):
    if ROW[i] != -1:
        GPIO.setup(ROW[i], GPIO.IN, pull_up_down=GPIO.PUD_UP)


try:
    os.mkfifo(fifo_path)
except Exception:
    pass

try:
    while True:

        # Set all columns as output low
        for j in range(len(COLUMN)):
            if COLUMN[j] != -1:
                GPIO.setup(COLUMN[j], GPIO.OUT)
                GPIO.output(COLUMN[j], GPIO.LOW)
 
        # Set all rows as input
        for i in range(len(ROW)):
            if ROW[i] != -1:
                GPIO.setup(ROW[i], GPIO.IN, pull_up_down=GPIO.PUD_UP)


        # Scan rows for pushed key/button
        # A valid key press should set "rowVal"  between 0 and 3.
        rowVal = -1
        for i in range(len(ROW)):
            if ROW[i] != -1:
                tmpRead = GPIO.input(ROW[i])
                if tmpRead == 0:
                    rowVal = i
                    # print "row pressed " + str(rowVal)


        # if rowVal is not 0 thru 3 then no button was pressed and we can exit
        if rowVal <0 or rowVal >3:
            # nothing pressed
            pass
        else:
            # Convert columns to input
            for j in range(len(COLUMN)):
                if COLUMN[j] != -1:
                    GPIO.setup(COLUMN[j], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
         
            # Switch the i-th row found from scan to output
            GPIO.setup(ROW[rowVal], GPIO.OUT)
            GPIO.output(ROW[rowVal], GPIO.HIGH)

            # Scan columns for still-pushed key/button
            # A valid key press should set "colVal"  between 0 and 3.
            colVal = -1
            for j in range(len(COLUMN)):
                if COLUMN[j] != -1:
                    tmpRead = GPIO.input(COLUMN[j])
                    if tmpRead == 1:
                        colVal=j
                        # print "col pressed " + str(colVal)


            # if colVal is not 0 thru 3 then no button was pressed and we can exit
                if colVal <0 or colVal >3:
                    # nothing pressed
                    pass
                else:
                    # print "B:row=" + str(rowVal) + " col=" + str(colVal) + " cur_button=" + str(cur_button)

                    if (last_button_press + button_press_min_delay_ms) <  int(round(time.time() * 1000)):
                        # reset current button
                        cur_button=-1

                    if rowVal == 0 and colVal == 0:
                        # button "1" pressed
                        if cur_button != 1:
                            #print "BUTTON:1"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:1\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=1
                    elif rowVal == 0 and colVal == 1:
                        # button "2" pressed
                        if cur_button != 2:
                            #print "BUTTON:2"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:2\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=2
                    elif rowVal == 3 and colVal == 0:
                        # button "*" pressed
                        if cur_button != 3:
                            #print "BUTTON:*"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("hangup:\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=3
                    elif rowVal == 3 and colVal == 1:
                        # button "0" pressed
                        if cur_button != 4:
                            #print "BUTTON:0"
                            #fifo_write = open(fifo_path, 'w')
                            #fifo_write.write("toggle_speaker:\n")
                            #fifo_write.flush()
                            #fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=4
                    elif rowVal == 3 and colVal == 2:
                        # button "#" pressed
                        if cur_button != 5:
                            #print "BUTTON:#"
                            #fifo_write = open(fifo_path, 'w')
                            #fifo_write.write("toggle_quality:\n")
                            #fifo_write.flush()
                            #fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=5
                    elif rowVal == 0 and colVal == 3:
                        # button "A" pressed
                        if cur_button != 6:
                            #print "BUTTON:A"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("BT-A:\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=6
                    elif rowVal == 1 and colVal == 3:
                        # button "B" pressed
                        if cur_button != 7:
                            #print "BUTTON:B"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("BT-B:\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=7
                    elif rowVal == 2 and colVal == 3:
                        # button "C" pressed
                        if cur_button != 8:
                            #print "BUTTON:C"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("BT-C:\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=8
                    elif rowVal == 3 and colVal == 3:
                        # button "D" pressed
                        if cur_button != 9:
                            #print "BUTTON:D"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("BT-D:\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=9
                    elif rowVal == 0 and colVal == 2:
                        # button "3" pressed
                        if cur_button != 10:
                            #print "BUTTON:3"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:3\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=10
                    elif rowVal == 1 and colVal == 0:
                        # button "4" pressed
                        if cur_button != 11:
                            #print "BUTTON:4"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:4\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=11
                    elif rowVal == 1 and colVal == 1:
                        # button "5" pressed
                        if cur_button != 12:
                            #print "BUTTON:5"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:5\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=12
                    elif rowVal == 1 and colVal == 2:
                        # button "6" pressed
                        if cur_button != 13:
                            #print "BUTTON:6"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:6\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=13
                    elif rowVal == 2 and colVal == 0:
                        # button "7" pressed
                        if cur_button != 14:
                            #print "BUTTON:7"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:7\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=14
                    elif rowVal == 2 and colVal == 1:
                        # button "8" pressed
                        if cur_button != 15:
                            #print "BUTTON:8"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:8\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=15
                    elif rowVal == 2 and colVal == 2:
                        # button "9" pressed
                        if cur_button != 16:
                            #print "BUTTON:9"
                            fifo_write = open(fifo_path, 'w')
                            fifo_write.write("call:9\n")
                            fifo_write.flush()
                            fifo_write.close()
                            last_button_press = int(round(time.time() * 1000))
                        cur_button=16
                    else:
                        # print "BUTTON:** -1 **"
                        cur_button=-1

        sleep(0.2)         # wait 0.2 seconds

finally:                   # this block will run no matter how the try block exits
    # fifo_write.close()
    GPIO.cleanup()         # clean up after yourself

