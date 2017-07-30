#! /bin/bash

file_rgba=~/ToxBlinkenwall/toxblinkenwall/gfx/tox_bw_clients.rgba

. $(dirname "$0")/vars.sh

$(dirname "$0")/stop_image_endless.sh
sleep 3

cat "$file_rgba" > "$fb_device"
