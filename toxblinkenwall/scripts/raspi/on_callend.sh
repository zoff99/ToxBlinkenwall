#! /bin/bash

# turn red led off
echo 'none' | sudo tee --append /sys/class/leds/led1/trigger
