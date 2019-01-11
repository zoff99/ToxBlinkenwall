#! /bin/bash

echo "restoring DEFAULT alsa config"
rm -f /tmp/alsa.$$.cfg
cp /usr/share/alsa/alsa.conf_ORIG /tmp/alsa.$$.cfg
sudo cp /tmp/alsa.$$.cfg /usr/share/alsa/alsa.conf
rm -f /tmp/alsa.$$.cfg
echo "... READY"


# detect Plantronics P610 ----------------
cat /proc/asound/card*/usbid |grep '047f:c02f'
res=$?
if [ $res -eq 0 ]; then
    echo "P610 detected ..."

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
	echo "using device ... READY"
fi




# detect Acusis v1.1.2.1 (UAC 1.0) ----------------
cat /proc/asound/card*/usbid |grep '20b1:0011'
res=$?
if [ $res -eq 0 ]; then
	echo "Acusis detected ..."

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
	echo "using device ... READY"
fi

# tell ToxBlinkenwall to reopen sound devices
echo "reopen_snd_devices:" > /home/pi/ToxBlinkenwall/toxblinkenwall/ext_keys.fifo

