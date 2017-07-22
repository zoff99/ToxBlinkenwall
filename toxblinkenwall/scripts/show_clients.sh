#! /bin/bash

file_rgba=~/ToxBlinkenwall/toxblinkenwall/gfx/tox_bw_clients.rgba

. $(dirname "$0")/vars.sh

cat "$file_rgba" > "$fb_device"
