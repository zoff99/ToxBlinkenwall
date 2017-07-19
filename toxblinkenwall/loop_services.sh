#! /bin/bash

function clean_up {

	# Perform program exit cleanup of framebuffer
	scripts/stop_loading_endless.sh
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=usr/lib

sudo /etc/init.d/lightdm start
sleep 4

trap clean_up SIGHUP SIGINT SIGTERM
scripts/stop_loading_endless.sh
scripts/init.sh
sleep 2
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/stop_loading_endless.sh
	scripts/init.sh
	./toxblinkenwall
	sleep 10
done

