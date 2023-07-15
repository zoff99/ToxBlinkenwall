#! /bin/bash

#*********************************
#
# ToxBlinkenwall - loop script
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

function clean_up
{
	pkill toxblinkenwall
	sleep 2
	pkill -9 toxblinkenwall
	pkill -9 toxblinkenwall
	pkill -f ext_keys_evdev.py
	pkill -f ext_keys.py
    pkill -f pizerow_stats_oled.sh
    rm -f ext_keys.fifo
	# Perform program exit cleanup of framebuffer
	scripts/stop_loading_endless.sh
	scripts/cleanup_fb.sh
    scripts/on_callend.sh
    scripts/on_offline.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=~/inst/lib/

HD_FROM_CAM="" # set to "-f" for 720p video
# you can switch it also later when Tox is running

# ---- only for RASPI ----
if [ "$IS_ON""x" == "RASPI""x" ]; then
	# camera module is never loaded automatically, why is that?
	sudo modprobe bcm2835_v4l2 # debug=5 # more debug info
	# nice now the module suddenly has a new name?
	sudo modprobe bcm2835-v4l2 # debug=5 # more debug info
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
chmod u+x scripts/*.py
chmod u+x scripts/raspi/*.sh
chmod u+x scripts/rpi_zerow/*.sh
chmod u+x scripts/linux/*.sh
chmod u+x toxblinkenwall
chmod u+x ext_keys_scripts/*.py
chmod u+x ext_keys_scripts/*.sh
chmod a+x udev2.sh udev.sh toggle_alsa.sh detect_usb_audio.sh alsa_mixer_ctrl.sh
scripts/stop_loading_endless.sh
scripts/stop_image_endless.sh
scripts/init.sh
sleep 1
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/stop_loading_endless.sh
	scripts/stop_image_endless.sh
	. scripts/vars.sh

	pkill -f ext_keys_evdev.py
	pkill -f ext_keys.py
    pkill -f pizerow_stats_oled.sh

    # just in case, so that udev scripts really really work
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-udevd

    hdmi_device_w=$(tvservice -s|awk -F',' '{print $2}'|tr -d ' '|cut -d'@' -f1|cut -d'x' -f 1)
    hdmi_device_h=$(tvservice -s|awk -F',' '{print $2}'|tr -d ' '|cut -d'@' -f1|cut -d'x' -f 2)
    cam_overlay_w=250
    cam_overlay_h=141
    cam_overlay_left_coord=$[ $hdmi_device_w - $cam_overlay_w - 12 ]
    cam_overlay_top_coord=$[ $hdmi_device_h - $cam_overlay_h - 9 ]

    v4l2-ctl -d "$video_device" -v width=1280,height=720,pixelformat=YV12
    v4l2-ctl -d "$video_device" --set-ctrl=scene_mode=0
    # v4l2-ctl -d "$video_device" --set-ctrl=exposure_dynamic_framerate=1 --set-ctrl=scene_mode=8
    v4l2-ctl -d "$video_device" --set-ctrl=h264_profile=4
    # v4l2-ctl -d "$video_device" --set-priority=3
    v4l2-ctl -d "$video_device" --set-ctrl=power_line_frequency=1
    v4l2-ctl -d "$video_device" -p 25
    # set own camera preview size
    v4l2-ctl -d "$video_device" --set-fmt-overlay=top="$cam_overlay_top_coord",left="$cam_overlay_left_coord",width="$cam_overlay_w",height="$cam_overlay_h"

    #        rotate (int)    : min=0 max=360 step=90 default=0 value=0 flags=00000400
    #
    #        white_balance_auto_preset (menu)   : min=0 max=9 default=1 value=1
    #				0: Manual
    #				1: Auto
    #				2: Incandescent
    #				3: Fluorescent
    #				4: Fluorescent H
    #				5: Horizon
    #				6: Daylight
    #				7: Flash
    #				8: Cloudy
    #				9: Shade
    #
    #        scene_mode (menu)   : min=0 max=13 default=0 value=0
    #				0: None
    #				8: Night
    #				11: Sports
    #
    #
    #        power_line_frequency (menu)   : min=0 max=3 default=1 value=1
    #				0: Disabled
    #				1: 50 Hz
    #				2: 60 Hz
    #				3: Auto
    #
    #        h264_profile (menu)   : min=0 max=4 default=4 value=4
    #				0: Baseline
    #				1: Constrained Baseline
    #				2: Main
    #				4: High
    #

    rm -f ext_keys.fifo
	cd ext_keys_scripts
	python3 ./ext_keys.py &
    nice python3 ./ext_keys_evdev.py &
	cd ..
    nice ./scripts/pizerow_stats_oled.sh &


    # ---- only for RASPI ----
    #if [ "$IS_ON""x" == "RASPI""x" ]; then
    #        sudo ./toggle_alsa.sh 1
    #fi
    # ---- only for RASPI ----

    # turn off visual cursor
	setterm -cursor off
    # turn off audible bell
    setterm -blength 0

    mkdir -p ./db/

    tor_option=" "
    if [ -f "OPTION_USETOR" ]; then
        tor_option=" -T "
    fi

    if [ -f "OPTION_USETCP" ]; then
        tor_option=" -t "
    fi

    # export ASAN_OPTIONS="malloc_context_size=100:check_initialization_order=true" # verbosity=2:
    export ASAN_OPTIONS=halt_on_error=0

    if [ -f "OPTION_USE_STDLOG" ]; then
        std_log=stdlog.log
    else
        std_log=/dev/null
    fi

    ulimit -c 99999
    v4l2-ctl --overlay=0
	./toxblinkenwall $HD_FROM_CAM $tor_option -u "$fb_device" -j "$BKWALL_WIDTH" -k "$BKWALL_HEIGHT" -d "$video_device" > "$std_log" 2>&1
    v4l2-ctl --overlay=0
    scripts/on_callend.sh
    scripts/on_offline.sh
    #
    if [ -f "OPTION_USE_STDLOG" ]; then
        # save debug info ---------------
        mv ./toxblinkenwall.2 ./toxblinkenwall.3
        mv ./core.2 ./core.3
        mv ./stdlog.log.2 ./stdlog.log.3
        # -------------------------------
        mv ./toxblinkenwall.1 ./toxblinkenwall.2
        mv ./core.1 ./core.2
        mv ./stdlog.log.1 ./stdlog.log.2
        # -------------------------------
        cp ./toxblinkenwall ./toxblinkenwall.1
        mv ./core ./core.1
        mv ./stdlog.log ./stdlog.log.1
        # save debug info ---------------
    fi
    #
	sleep 4

    # ---- only for RASPI ----
    #if [ "$IS_ON""x" == "RASPI""x" ]; then
    #        sudo ./toggle_alsa.sh 1
    #fi
    # ---- only for RASPI ----

    if [ -f "OPTION_NOLOOP" ]; then
        # do not loop/restart
        clean_up
        exit 1
    fi

done

