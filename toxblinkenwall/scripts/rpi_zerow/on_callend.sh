#! /bin/bash

# turn red led off
echo 'default-on' | sudo tee --append /sys/class/leds/led1/trigger
