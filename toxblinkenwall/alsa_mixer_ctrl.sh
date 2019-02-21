#! /bin/bash

want_up_="$1"
if [ "$want_up_""x" == "0x" ];then
    want_up=0
else
    want_up=1
fi

for device_num in 0 1; do
    # loop through all playback volumes
    amixer -c"$device_num" scontrols 2>&1|head -3|grep -i 'invalid card number'
    device_valid=$?
    if [ $device_valid -eq 1 ]; then
        for ctrl in $(amixer -c"$device_num" scontrols |sed -e 's#Simple mixer control ##'); do
            echo $ctrl
            amixer -c"$device_num" sget "$ctrl"|grep -i 'pvolume'
            is_playback=$?
            echo $is_playback
            if [ $is_playback -eq 0 ]; then
                if [ "$want_up""x" == "1x" ]; then
                    amixer -M -c"$device_num" sset "$ctrl" "3dB+" unmute
                else
                    amixer -M -c"$device_num" sset "$ctrl" "3dB-" unmute
                fi
            fi
        done
    fi
done



if [ 1 == 2 ]; then

for device_num in 0 1; do

    # loop through all playback volumes
    num_id=$(amixer -c"$device_num" controls |grep 'iface=MIXER'|grep -i 'volume'|grep -i 'playback'|cut -f1 -d ','|cut -d"=" -f2|tr -d ' ')
    if [ "$num_id""x" == "x" ]; then
        echo "Error:Playback:001"
    elif [ "$num_id""x" == "Invalid card number.x" ]; then
        echo "Error:Playback:002"
    else
        echo "Playback:$num_id"
        # amixer -c"$device_num" cget "numid=""$num_id"
        amixer -M -c"$device_num" cset "numid=""$num_id" "$play_percent""%"
    fi

    # loop through all capture volumes
    num_id=$(amixer -c"$device_num" controls |grep 'iface=MIXER'|grep -i 'volume'|grep -i 'capture'|cut -f1 -d ','|cut -d"=" -f2|tr -d ' ')
    if [ "$num_id""x" == "x" ]; then
        echo "Error:Capture:001"
    elif [ "$num_id""x" == "Invalid card number.x" ]; then
        echo "Error:Capture:002"
    else
        echo "Capture:$num_id"
        # amixer -c"$device_num" cget "numid=""$num_id"
        amixer -M -c"$device_num" cset "numid=""$num_id" "$capture_percent""%"
    fi

done

fi
