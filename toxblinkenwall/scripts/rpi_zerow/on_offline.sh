#! /bin/bash

# turn green led off, when offline
echo 'default-on' | sudo tee --append /sys/class/leds/led0/trigger 

echo "*offline*" > /home/pi/ToxBlinkenwall/toxblinkenwall/share/online_status.txt
