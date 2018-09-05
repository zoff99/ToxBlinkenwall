#! /bin/bash

function background
{

qrcode_file_rgba=$(dirname "$0")/../toxid.rgba

. $(dirname "$0")/vars.sh

$(dirname "$0")/stop_image_endless.sh
sleep 1.2

cat "$qrcode_file_rgba" > "$fb_device"

}

background &

