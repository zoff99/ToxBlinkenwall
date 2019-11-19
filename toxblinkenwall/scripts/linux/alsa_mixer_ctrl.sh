#! /bin/bash

want_up_="$1"
if [ "$want_up_""x" == "0x" ];then
    want_up=0
elif [ "$want_up_""x" == "2x" ];then
    want_up=2
else
    want_up=1
fi

export mapped_volume=" -M "

current_value_percent=0

# loop through all playback volumes
if [ "$want_up""x" == "2x" ]; then
    :
    # just return current value, without setting anything
else
    if [ "$want_up""x" == "1x" ]; then
        amixer $mapped_volume sset "Master" "10%+" >/dev/null 2>&1
    else
        amixer $mapped_volume sset "Master" "10%-" >/dev/null 2>&1
    fi
fi

current_value_percent_=$(amixer "$mapped_volume" sget Master >/dev/null | awk -F"[][]" '/%/ { print $2 }' >/dev/null | grep '%' >/dev/null | head -1 >/dev/null | sed -e 's/%//' >/dev/null)

current_value_percent_=$[ $[ $current_value_percent_ + 1 ] - 1 ]
# echo $current_value_percent_
if [ $current_value_percent_ -le 100 ] && [ $current_value_percent_ -ge 0 ]; then
    current_value_percent=$current_value_percent_
fi

echo "CURVALUE:""$current_value_percent"
