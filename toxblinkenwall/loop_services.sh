#! /bin/bash

function clean_up
{
	pkill toxblinkenwall
	sleep 2
	pkill -9 toxblinkenwall
	pkill -9 toxblinkenwall
	# Perform program exit cleanup of framebuffer
	scripts/stop_loading_endless.sh
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=~/inst/lib/

# ---- only for RASPI ----
if [ "$IS_ON""x" == "RASPI""x" ]; then
	# camera module not loaded automatically
	sudo modprobe bcm2835_v4l2
	# stop gfx UI
	# sudo /etc/init.d/lightdm start
	# sleep 2

	sudo sed -i -e 's#BLANK_TIME=.*#BLANK_TIME=0#' /etc/kbd/config
	sudo sed -i -e 's#POWERDOWN_TIME=.*#POWERDOWN_TIME=0#' /etc/kbd/config
	sudo setterm -blank 0 > /dev/null 2>&1
	sudo setterm -powerdown 0 > /dev/null 2>&1
	
	openvt -- sudo sh -c "/bin/chvt 1 >/dev/null 2>/dev/null"
	sudo sh -c "TERM=linux setterm -blank 0 >/dev/tty0"
fi
# ---- only for RASPI ----

trap clean_up SIGHUP SIGINT SIGTERM SIGKILL

chmod u+x scripts/*.sh
chmod u+x toxblinkenwall
scripts/stop_loading_endless.sh
scripts/stop_image_endless.sh
scripts/init.sh
sleep 1
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/stop_loading_endless.sh
	scripts/stop_image_endless.sh
	# scripts/init.sh
	. scripts/vars.sh
	./toxblinkenwall -d "$video_device" -u "$fb_device" -j "$BKWALL_WIDTH" -k "$BKWALL_HEIGHT"
	sleep 2
	# ---- only for RASPI ----
	if [ "$IS_ON""x" == "RASPI""x" ]; then
		:
		# stop gfx UI
		# sudo /etc/init.d/lightdm start
		# sleep 2
	fi
	# ---- only for RASPI ----
done

