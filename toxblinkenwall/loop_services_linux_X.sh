#! /bin/bash

function clean_up
{
	pkill toxblinkenwall
	sleep 2
	pkill -9 toxblinkenwall
	pkill -9 toxblinkenwall
	pkill -f ext_keys.py
	# Perform program exit cleanup of framebuffer
	# scripts/stop_loading_endless.sh
	# scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=~/inst/lib/

trap clean_up SIGHUP SIGINT SIGTERM SIGKILL

chmod u+x scripts/*.sh
chmod u+x toxblinkenwall
chmod u+x ext_keys_scripts/ext_keys.py
chmod a+x udev2.sh udev.sh toggle_alsa.sh
sleep 1

while [ 1 == 1 ]; do
	. scripts/vars.sh

	pkill -f ext_keys.py

	v4l2-ctl -d "$video_device" -v width=1280,height=720,pixelformat=YV12
    v4l2-ctl -d "$video_device" -p 25

	cd ext_keys_scripts
	./ext_keys.py &
	cd ..

	./toxblinkenwall -d "$video_device" -u "$fb_device" -j "$BKWALL_WIDTH" -k "$BKWALL_HEIGHT"
	sleep 2

done

