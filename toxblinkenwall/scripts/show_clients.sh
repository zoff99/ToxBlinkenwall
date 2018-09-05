#! /bin/bash

function background
{

file_rgba=$(dirname "$0")/../gfx/tox_bw_clients.rgba

. $(dirname "$0")/vars.sh

$(dirname "$0")/stop_image_endless.sh
sleep 3

cat "$file_rgba" > "$fb_device"

}

background &


