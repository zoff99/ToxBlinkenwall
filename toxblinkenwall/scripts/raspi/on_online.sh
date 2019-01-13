#! /bin/bash

# turn green led on, when online
echo 'default-on' | sudo tee --append /sys/class/leds/led0/trigger 
