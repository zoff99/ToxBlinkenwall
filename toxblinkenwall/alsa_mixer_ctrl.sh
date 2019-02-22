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

for device_num in 0 1; do
    # loop through all playback volumes
    amixer -c"$device_num" scontrols 2>&1|head -3|grep -i 'invalid card number' >/dev/null 2>&1
    device_valid=$?
    if [ $device_valid -eq 1 ]; then
        for ctrl in $(amixer -c"$device_num" scontrols |sed -e 's#Simple mixer control ##'); do
            # echo $ctrl
            amixer -c"$device_num" sget "$ctrl"|grep -i 'pvolume' >/dev/null 2>&1
            is_playback=$?
            # echo $is_playback
            if [ $is_playback -eq 0 ]; then
                if [ "$want_up""x" == "2x" ]; then
                    :
                    # just return current value, without setting anything
                else
                    if [ "$want_up""x" == "1x" ]; then
                        amixer $mapped_volume -c"$device_num" sset "$ctrl" "3dB+" unmute >/dev/null 2>&1
                    else
                        amixer $mapped_volume -c"$device_num" sset "$ctrl" "3dB-" unmute >/dev/null 2>&1
                    fi
                fi
            fi
        done
        current_value_percent_=$(amixer $mapped_volume -c"$device_num"|grep -i "playback"|grep '%'|grep -o '[^\[]*%'|sed -e 's#%##'|tr -d ' ')
        current_value_percent_=$[ $[ $current_value_percent_ + 1 ] - 1 ]
        # echo $current_value_percent_
        if [ $current_value_percent_ -le 100 ] && [ $current_value_percent_ -ge 0 ]; then
            current_value_percent=$current_value_percent_
        fi

    fi
done

echo "CURVALUE:""$current_value_percent"
