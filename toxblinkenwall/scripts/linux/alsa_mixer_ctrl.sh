#! /bin/bash

want_up_="$1"
if [ "$want_up_""x" == "0x" ];then
    want_up=0
elif [ "$want_up_""x" == "2x" ];then
    want_up=2
else
    want_up=1
fi

mapped_volume=" -M "

current_value_percent=0

# loop through all playback volumes
if [ "$want_up""x" == "2x" ]; then
    :
    # just return current value, without setting anything
else
    if [ "$want_up""x" == "1x" ]; then
        amixer $mapped_volume set Master "3dB+"
    else
        amixer $mapped_volume set Master "3dB-"
    fi
fi

current_value_percent_=$(awk -F"[][]" '/dB/ { print $2 }' <(amixer "$mapped_volume" sget Master) | sed -e s/%//)

current_value_percent_=$[ $[ $current_value_percent_ + 1 ] - 1 ]
# echo $current_value_percent_
if [ $current_value_percent_ -le 100 ] && [ $current_value_percent_ -ge 0 ]; then
    current_value_percent=$current_value_percent_
fi

echo "CURVALUE:""$current_value_percent"
