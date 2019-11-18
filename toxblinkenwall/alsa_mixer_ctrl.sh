#! /bin/bash

want_up_="$1"
if [ "$want_up_""x" == "0x" ];then
    want_up=0
elif [ "$want_up_""x" == "2x" ];then
    want_up=2
else
    want_up=1
fi

# loop through all playback volumes
if [ "$want_up""x" == "2x" ]; then
    :
# just return current value, without setting anything
else
    if [ "$want_up""x" == "1x" ]; then
        amixer set Master 3dB+
    else
        amixer set Master 3dB-
    fi
fi

current_value_percent=$(awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master) | sed -e s/%//)
echo "CURVALUE:""$current_value_percent"
