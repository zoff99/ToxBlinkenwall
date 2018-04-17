#! /usr/bin/env python

import RPi.GPIO as GPIO
from time import sleep     # this lets us have a time delay (see line 15)
GPIO.setmode(GPIO.BCM)     # set up BCM GPIO numbering

# What Raspberry Pi revision are we running?
GPIO.RPI_REVISION    #  0 = Compute Module, 1 = Rev 1, 2 = Rev 2, 3 = Model B+

# What version of RPi.GPIO are we running?
GPIO.VERSION

fifo_path = '../ext_keys.fifo'
cur_button=-1

ROW    = [16, 20, 21, 5] # these are the GPIO numbers, NOT the real PIN numbers
COLUMN = [6, 13, 19, 26]

fifo_write = open(fifo_path, 'w')

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
                    # print "row=" + str(rowVal) + " col=" + str(colVal)

                    if rowVal == 0 and colVal == 0 and cur_button != 1:
                        # button "1" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("call:1\n")
                        fifo_write.flush()
                        cur_button=1
                    elif rowVal == 0 and colVal == 1 and cur_button != 2:
                        # button "2" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("call:2\n")
                        fifo_write.flush()
                        cur_button=2
                    elif rowVal == 3 and colVal == 0 and cur_button != 3:
                        # button "*" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("hangup:\n")
                        fifo_write.flush()
                        cur_button=3
                    elif rowVal == 3 and colVal == 1 and cur_button != 4:
                        # button "0" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("toggle_speaker:\n")
                        fifo_write.flush()
                        cur_button=4
                    elif rowVal == 3 and colVal == 2 and cur_button != 5:
                        # button "#" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("toggle_quality:\n")
                        fifo_write.flush()
                        cur_button=5
                    else:
                        cur_button=-1

        sleep(0.1)         # wait 0.1 seconds

finally:                   # this block will run no matter how the try block exits

    fifo_write.close()

    GPIO.cleanup()         # clean up after yourself

