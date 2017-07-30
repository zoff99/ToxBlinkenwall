#! /bin/bash

qrcode_file_rgba=~/ToxBlinkenwall/toxblinkenwall/toxid.rgba

. $(dirname "$0")/vars.sh

$(dirname "$0")/stop_image_endless.sh
sleep 3

cat "$qrcode_file_rgba" > "$fb_device"
