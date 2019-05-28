#! /bin/bash

# turn red led off
echo 'default-on' | sudo tee --append /sys/class/leds/led1/trigger

echo "CALL ended" > /home/pi/ToxBlinkenwall/toxblinkenwall/share/online_status.txt
