#! /bin/bash

# turn green led off
echo 'none' | sudo tee --append /sys/class/leds/led0/trigger

# turn red led off
echo 'none' | sudo tee --append /sys/class/leds/led1/trigger

echo "-starting-" > /home/pi/ToxBlinkenwall/toxblinkenwall/share/online_status.txt
