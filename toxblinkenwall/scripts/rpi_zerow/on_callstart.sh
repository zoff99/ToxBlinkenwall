#! /bin/bash

# turn red led on
echo 'none' | sudo tee --append /sys/class/leds/led1/trigger
