#! /bin/bash

# turn green led on, when online
echo 'none' | sudo tee --append /sys/class/leds/led0/trigger 
