#! /bin/bash

# turn green led off, when offline
echo 'none' | sudo tee --append /sys/class/leds/led0/trigger 
