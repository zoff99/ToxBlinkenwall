#! /bin/bash

#*********************************
#
# ToxBlinkenwall - udev script to detect audio and video devices
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************


export usb_device="$1"
export dst_dir=$(dirname "$0")
export logfile="$dst_dir""/tox_usbmount.log"

touch "$logfile"
chmod a+rw "$logfile" 2> /dev/null # file owned by root (since this is an udev script)
chown pi:pi "$logfile" 2> /dev/null # file owned by root (since this is an udev script)

echo "UDEV-CALL:AV:$2:$3" >> "$logfile"

if [ "$3""x" == "drivex" ]; then
    # do not process usb-drives in this script
    exit 0
fi


re=".*/video[0-9]"
if [[ "$1" =~ $re ]]; then
    echo "skipping sound devices detection" >> "$logfile" 2>&1
else

echo "restoring DEFAULT alsa config" >> "$logfile" 2>&1
rm -f /tmp/alsa.$$.cfg
cp -v /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg >> "$logfile" 2>&1
sudo cp -v /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf >> "$logfile" 2>&1
rm -f /tmp/alsa.$$.cfg
echo "... READY" >> "$logfile" 2>&1


detected_supported_device=0

# detect Sony Playstation Eye ------------
cat /proc/asound/card*/usbid |grep '1415:2000'
res=$?
if [ $res -eq 0 ]; then
    echo "Sony Playstation Eye detected ..." >> "$logfile" 2>&1
	cp -v /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg >> "$logfile" 2>&1
	echo '
pcm.usb
{
    type hw
    card CameraB409241
}

pcm.card_bcm {
    type hw
    card ALSA
}

pcm.!default {
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "card_bcm"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}

defaults.pcm.!card ALSA
' >> /tmp/alsa.$$.cfg


	sudo cp -v /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf >> "$logfile" 2>&1
	rm -f /tmp/alsa.$$.cfg
	echo "using device ... READY" >> "$logfile" 2>&1
    detected_supported_device=1
fi



# detect Plantronics P610 ----------------
cat /proc/asound/card*/usbid |grep '047f:c02f'
res=$?
if [ $res -eq 0 ]; then
    echo "P610 detected ..." >> "$logfile" 2>&1

	cp /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg
	echo '
pcm.usb
{
    type hw
    card P610
}

pcm.card_bcm {
    type hw
    card ALSA
}

pcm.!default {
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "usb"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}

defaults.pcm.!card ALSA
' >> /tmp/alsa.$$.cfg


	sudo cp /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf
	rm -f /tmp/alsa.$$.cfg
	echo "using device ... READY" >> "$logfile" 2>&1
    detected_supported_device=1
fi




# detect Acusis v1.1.2.1 (UAC 1.0) ----------------
cat /proc/asound/card*/usbid |grep '20b1:0011'
res=$?
if [ $res -eq 0 ]; then
	echo "Acusis detected ..." >> "$logfile" 2>&1

	cp /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg
	echo '
pcm.usb
{
    type hw
    card A10
}

pcm.card_bcm {
    type hw
    card ALSA
}

pcm.!default {
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "usb"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}

defaults.pcm.!card ALSA
' >> /tmp/alsa.$$.cfg


	sudo cp /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf
	rm -f /tmp/alsa.$$.cfg
	echo "using device ... READY" >> "$logfile" 2>&1
    detected_supported_device=1
fi


# detect USB PhoneReceiver ----------------
cat /proc/asound/card*/usbid |grep '04b4:0306'
res=$?
if [ $res -eq 0 ]; then
    echo "USB PhoneReceiver detected ..." >> "$logfile" 2>&1

	cp /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg
	echo '
pcm.usb
{
    type hw
    card U0x4b40x306
}

pcm.card_bcm {
    type hw
    card ALSA
}

pcm.!default {
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "usb"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}

defaults.pcm.!card ALSA
' >> /tmp/alsa.$$.cfg


	sudo cp /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf
	rm -f /tmp/alsa.$$.cfg
	echo "using device ... READY" >> "$logfile" 2>&1
    detected_supported_device=1
fi


if [ "$detected_supported_device""x" == "0x" ]; then
    some_usb_sound_device_dectect=0
    # try to use the first USB sound device connected to the system
    if [ -f /proc/asound/card0/usbid ]; then
        usb_device_name=$(cat /proc/asound/card0/id)
        some_usb_sound_device_dectect=1
    elif [ -f /proc/asound/card1/usbid ]; then
        usb_device_name=$(cat /proc/asound/card1/id)
        some_usb_sound_device_dectect=1
    elif [ -f /proc/asound/card2/usbid ]; then
        usb_device_name=$(cat /proc/asound/card2/id)
        some_usb_sound_device_dectect=1
    elif [ -f /proc/asound/card3/usbid ]; then
        usb_device_name=$(cat /proc/asound/card3/id)
        some_usb_sound_device_dectect=1
    fi

    if [ "$some_usb_sound_device_dectect""x" == "1x" ]; then

        echo "unknown USB sound device detected ..." >> "$logfile" 2>&1

        cp /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg
        echo '
pcm.usb
{
    type hw
    card '"$usb_device_name"'
}

pcm.card_bcm {
    type hw
    card ALSA
}

pcm.!default {
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "usb"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}

defaults.pcm.!card ALSA
' >> /tmp/alsa.$$.cfg

        sudo cp /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf
        rm -f /tmp/alsa.$$.cfg
        echo "using device ... READY" >> "$logfile" 2>&1
    fi
fi


# tell ToxBlinkenwall to reopen sound devices
if [ -p "/home/pi/ToxBlinkenwall/toxblinkenwall/ext_keys.fifo" ]; then
    echo "reopen snd devices" >> "$logfile" 2>&1
    echo "reopen_snd_devices:" > /home/pi/ToxBlinkenwall/toxblinkenwall/ext_keys.fifo
fi

fi

## --------------- VIDEO ---------------

re=".*/video[0-9]"
if [[ "$1" =~ $re ]]; then

    echo "processing video device $1 ..." >> "$logfile" 2>&1
    
    sleep 2

    video_device_to_use=$(ls -1r /dev/video[0-9]* 2>/dev/null|head -1 2> /dev/null|tr -d " " 2>/dev/null|tr -d '\n' 2>/dev/null | tr -d '\r' 2>/dev/null)

    if [ "$video_device_to_use""x" == "x" ]; then
        video_device_to_use="/dev/video0" # use default value on error or on no-cam-device-found
    fi

    # tell ToxBlinkenwall to reopen sound devices
    if [ -p "/home/pi/ToxBlinkenwall/toxblinkenwall/ext_keys.fifo" ]; then
        echo "reopen vid devices:$video_device_to_use" >> "$logfile" 2>&1
        echo "reopen_vid_devices:""$video_device_to_use" > /home/pi/ToxBlinkenwall/toxblinkenwall/ext_keys.fifo
    fi

fi