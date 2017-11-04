#! /usr/bin/env python

import RPi.GPIO as GPIO
from time import sleep     # this lets us have a time delay (see line 15)
GPIO.setmode(GPIO.BCM)     # set up BCM GPIO numbering

# What Raspberry Pi revision are we running?
GPIO.RPI_REVISION    #  0 = Compute Module, 1 = Rev 1, 2 = Rev 2, 3 = Model B+

# What version of RPi.GPIO are we running?
GPIO.VERSION

fifo_path = '../ext_keys.fifo'

# Set all rows as input --------------------------
input_4 = 0 # row 1
input_17 = 0 # row 4
# Set all rows as input --------------------------

# Set all columns as output low ------------------
input_27 = 0 # col 1
input_22 = 0 # col 3
# Set all columns as output low ------------------

ROW    = [4, -1, -1, 17]
COLUMN = [27, -1, 22]

fifo_write = open(fifo_path, 'w')

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
                    # print "row pressed" + str(rowVal)


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
            # A valid key press should set "colVal"  between 0 and 2.
            colVal = -1
            for j in range(len(COLUMN)):
                if COLUMN[j] != -1:
                    tmpRead = GPIO.input(COLUMN[j])
                    if tmpRead == 1:
                        colVal=j
                        # print "col pressed" + str(colVal)


            # if colVal is not 0 thru 2 then no button was pressed and we can exit
                if colVal <0 or colVal >2:
                    # nothing pressed
                    pass
                else:
                    # print "row=" + str(rowVal) + " col=" + str(colVal)

                    if rowVal == 0 and colVal == 0:
                        # button "1" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("call:1\n")
                        fifo_write.flush()
                    elif rowVal == 3 and colVal == 0:
                        # button "*" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("hangup:\n")
                        fifo_write.flush()
                    elif rowVal == 3 and colVal == 2:
                        # button "#" pressed
                        fifo_write = open(fifo_path, 'w')
                        fifo_write.write("toggle_quality:\n")
                        fifo_write.flush()


        sleep(0.2)         # wait 0.2 seconds

finally:                   # this block will run no matter how the try block exits

    fifo_write.close()

    # GPIO.setup(4, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    # GPIO.setup(17, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    # GPIO.setup(27, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    # GPIO.setup(22, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    GPIO.cleanup()         # clean up after yourself

