#! /bin/bash

# turn red led on
echo 'default-on' | sudo tee --append /sys/class/leds/led1/trigger
