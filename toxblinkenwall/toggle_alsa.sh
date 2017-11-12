#! /bin/bash

alsa_out_num="$1"
global_alsa_config="/usr/share/alsa/alsa.conf"
alsa_config_0="/usr/share/alsa/alsa_0.conf"
alsa_config_1="/usr/share/alsa/alsa_1.conf"

if [ "$alsa_out_num""x" == "0x" ]; then
	cp "$alsa_config_0" "$global_alsa_config"
else
	cp "$alsa_config_1" "$global_alsa_config"
fi

