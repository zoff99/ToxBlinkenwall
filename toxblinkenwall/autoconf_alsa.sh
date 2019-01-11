#!/bin/sh

PL610=047f:c02f

NEED_PLUGHW_IDS="$PL610"

ALSA_HWID="hw:1,0"

ASOUND_CONF=$(cat << END
	pcm.!default {
	  type plug
	  slave {
	    pcm "$ALSA_HWID"
	  }
	}
END
)

for usbid in $NEED_PLUGHW_IDS ; do
 if lsusb | grep -c $usbid > /dev/null ; then
   NEED_PLUGHW=1
 fi
done

if [ "$NEED_PLUGHW" = 1 ]; then
   echo "$ASOUND_CONF" > /etc/asound.conf
fi
