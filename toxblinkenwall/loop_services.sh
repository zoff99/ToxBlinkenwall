#! /bin/bash

function clean_up
{
	pkill toxblinkenwall
	sleep 1
	pkill -9 toxblinkenwall
	pkill -9 toxblinkenwall
	# Perform program exit cleanup of framebuffer
	scripts/stop_loading_endless.sh
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=usr/lib

# ---- only for RASPI ----
if [ "$IS_ON""x" == "RASPI""x" ]; then
	# camera module not loaded automatically
	sudo modprobe bcm2835_v4l2
	# stop gfx UI
	sudo /etc/init.d/lightdm start
	sleep 2
fi
# ---- only for RASPI ----

trap clean_up SIGHUP SIGINT SIGTERM

chmod u+x scripts/*.sh
chmod u+x toxblinkenwall
scripts/stop_loading_endless.sh
scripts/stop_image_endless.sh
scripts/init.sh
sleep 2
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/stop_loading_endless.sh
	scripts/stop_image_endless.sh
	scripts/init.sh
	. scripts/vars.sh
	./toxblinkenwall -d "$video_device" -u "$fb_device" -j "$BKWALL_WIDTH" -k "$BKWALL_HEIGHT"
	sleep 10
done

