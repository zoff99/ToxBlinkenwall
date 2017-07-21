#! /bin/bash

qrcode_file_rgba=~/ToxBlinkenwall/toxblinkenwall/toxid.rgba

. $(dirname "$0")/vars.sh

cat "$qrcode_file_rgba" > "$fb_device"
