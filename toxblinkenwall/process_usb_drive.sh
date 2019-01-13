#! /bin/bash

#*********************************
#
# ToxBlinkenwall - udev script - part 2
# (C)Zoff in 2017
#
# https://github.com/zoff99/ToxBlinkenwall
#
# TODO: cleanup and write nicer
#
#*********************************


export usb_device="$1"
export mount_dir="/usb_device___/"
export dst_dir=$(dirname "$0")
export logfile="$dst_dir""/tox_usbmount.log"

touch /tmp/usb_stick.txt

sleep 2

touch "$logfile"
chmod a+rw "$logfile" 2> /dev/null


function import_data
{
    usb_device_to_use="$1"

    rm -Rf "$mount_dir"/
    mkdir -p "$mount_dir"
    echo "mounting $usb_device_to_use ..." >> "$logfile"
    mount "$usb_device_to_use" "$mount_dir" >> "$logfile" 2>&1
    res=$?
    
    if [ $res -ne 0 ]; then
        rm -Rf "$mount_dir"/
        echo "error mounting $usb_device_to_use" >> "$logfile"
        return 1
    fi

    for num_entry in book_entry_1.txt \
    book_entry_2.txt \
    book_entry_3.txt \
    book_entry_4.txt \
    book_entry_5.txt \
    book_entry_6.txt \
    book_entry_7.txt \
    book_entry_8.txt \
    book_entry_9.txt ; do

        if [ -e "$mount_dir""/""$num_entry" ]; then
                ls -al "$mount_dir""$num_entry" >> "$logfile"
                cp -v "$mount_dir""$num_entry" "$dst_dir""/" >> "$logfile" 2>&1
                chmod a+rw "$dst_dir""/""$num_entry"
        fi

    done


    if [ -e "$mount_dir""/""wlan_ssid.txt" ]; then

        wpa_net_country="AT" # TODO: also make this a parameter?
        wpa_net_id_rand=$(( ( RANDOM % 100000 )  + 1 ))

        ########-------------------------------------

        wpa_conf_file_location="/etc/wpa_supplicant/wpa_supplicant.conf"
        wpa_conf_file_mode="600"
        wpa_conf_file_content_001='country=@NETCOUNTRY@
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="'

        wpa_conf_file_content_002='"
    scan_ssid=1
    psk="'

        wpa_conf_file_content_003='"
    key_mgmt=WPA-PSK
    mode=0
    proto=WPA2
    pairwise=CCMP
    group=CCMP
    auth_alg=OPEN
    id_str="ToxPhone@RAND@"
    priority=1
}
'

        wpa_conf_file_content_openwlan='
network={
    key_mgmt=NONE
    priority=-999
}
'

        ########-------------------------------------

        rm -f "/tmp/abc.txt"

        rm -f "/tmp/abc001.txt"

        echo -n "$wpa_conf_file_content_001" \
          | sed -e 's#@NETCOUNTRY@#'"$wpa_net_country"'#' \
          > "/tmp/abc001.txt"

        chmod og-rwx "/tmp/abc001.txt"

        rm -f "/tmp/abc003.txt"

        echo -n "$wpa_conf_file_content_003" \
          | sed -e 's#@RAND@#'"$wpa_net_id_rand"'#' \
          > "/tmp/abc003.txt"

        chmod og-rwx "/tmp/abc003.txt"

        cat "/tmp/abc001.txt" > "/tmp/abc.txt"
        cat "$mount_dir""/""wlan_ssid.txt"|head -1|tr -d '\r'|tr -d '\n' >> "/tmp/abc.txt"
        echo -n "$wpa_conf_file_content_002" >> "/tmp/abc.txt"
        cat "$mount_dir""/""wlan_pass.txt"|head -1|tr -d '\r'|tr -d '\n' >> "/tmp/abc.txt"
        cat "/tmp/abc003.txt" >> "/tmp/abc.txt"

        rm -f "/tmp/abc001.txt" "/tmp/abc003.txt"

        if [ -e "$mount_dir""/""wlan_public.txt" ]; then
            echo "$wpa_conf_file_content_openwlan" >> "/tmp/abc.txt"
        fi

        chmod $wpa_conf_file_mode "/tmp/abc.txt"

        mv -v "/tmp/abc.txt" "$wpa_conf_file_location"
        rm -f "/tmp/abc.txt" # just to be safe

        wpa_action wlan0 reload
        systemctl restart ifup@wlan0.service

    fi


    echo "UNmounting $usb_device_to_use ..." >> "$logfile"
    umount "$mount_dir" >> "$logfile" 2>&1
    rm -Rf "$mount_dir"/

    return 0
}

function export_data
{
    usb_device_to_use="$1"

    rm -Rf "$mount_dir"/
    mkdir -p "$mount_dir"
    echo "mounting $usb_device_to_use ..." >> "$logfile"
    mount "$usb_device_to_use" "$mount_dir" >> "$logfile" 2>&1
    res=$?
    
    if [ $res -ne 0 ]; then
        rm -Rf "$mount_dir"/
        echo "error mounting $usb_device_to_use" >> "$logfile"
        return 1
    fi

    mkdir -p "$mount_dir""/""backup/"
    echo "backing up:Tox Privkey and Friends" >> "$logfile"
    cp -v "$dst_dir""/"savedata.tox "$mount_dir""/""backup/" >> "$logfile" 2>&1

    echo "UNmounting $usb_device_to_use ..." >> "$logfile"
    umount "$mount_dir" >> "$logfile" 2>&1
    rm -Rf "$mount_dir"/

    return 0

}

## Main Program ------

echo "import data 1:$usb_device" >> "$logfile"
import_data "$usb_device"
res=$?
if [ $res -ne 0 ]; then
    echo "import data 2:$usb_device""1" >> "$logfile"
    import_data "$usb_device""1"
fi

echo "export data 1:$usb_device" >> "$logfile"
export_data "$usb_device"
res=$?
if [ $res -ne 0 ]; then
    echo "export data 2:$usb_device""1" >> "$logfile"
    export_data "$usb_device""1"
fi
