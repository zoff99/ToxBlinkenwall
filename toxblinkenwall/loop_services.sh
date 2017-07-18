#! /bin/bash

function clean_up {

	# Perform program exit cleanup of framebuffer
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=usr/lib

sudo /etc/init.d/lightdm start
sleep 10

trap clean_up SIGHUP SIGINT SIGTERM
scripts/init.sh
sleep 2
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/init.sh
	./toxblinkenwall
	sleep 10
done

