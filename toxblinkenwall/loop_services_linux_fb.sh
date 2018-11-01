#! /bin/bash

function clean_up
{
	pkill toxblinkenwall
	sleep 2
	pkill -9 toxblinkenwall
	pkill -9 toxblinkenwall
	pkill -f ext_keys.py
	# Perform program exit cleanup of framebuffer
	scripts/stop_loading_endless.sh
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")

HD_FROM_CAM="" # set to "-f" for 720p video
# you can switch it also later when Tox is running

sudo openvt -f -c 12
sudo chvt 12

# ---- only for RASPI ----
if [ "$IS_ON""x" == "RASPI""x" ]; then
	#sudo sed -i -e 's#BLANK_TIME=.*#BLANK_TIME=0#' /etc/kbd/config
	#sudo sed -i -e 's#POWERDOWN_TIME=.*#POWERDOWN_TIME=0#' /etc/kbd/config
	#sudo setterm -blank 0 > /dev/null 2>&1
	#sudo setterm -powerdown 0 > /dev/null 2>&1
	# openvt -- sudo sh -c "/bin/chvt 1 >/dev/null 2>/dev/null"
	# sudo sh -c "TERM=linux setterm -blank 0 >/dev/tty0"
	:
fi
# ---- only for RASPI ----

trap clean_up SIGHUP SIGINT SIGTERM SIGKILL

chmod u+x scripts/*.sh
chmod u+x toxblinkenwall
chmod u+x ext_keys_scripts/ext_keys.py
chmod a+x udev2.sh udev.sh toggle_alsa.sh
scripts/stop_loading_endless.sh
scripts/stop_image_endless.sh
scripts/init.sh
sleep 1
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/stop_loading_endless.sh
	scripts/stop_image_endless.sh
	. scripts/vars.sh

	pkill -f ext_keys.py

    v4l2-ctl -d "$video_device" -v width=1280,height=720,pixelformat=YV12
    v4l2-ctl -d "$video_device" -p 25

	setterm -cursor off
	./toxblinkenwall $HD_FROM_CAM -u "$fb_device" -j "$BKWALL_WIDTH" -k "$BKWALL_HEIGHT" -d "$video_device" >/dev/null 2>/dev/null
	sleep 2

	# exit 1

    # ---- only for RASPI ----
done

