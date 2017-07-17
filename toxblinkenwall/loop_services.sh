#! /bin/bash

function clean_up {

	# Perform program exit cleanup of framebuffer
	scripts/cleanup_fb.sh
	exit
}

cd $(dirname "$0")
export LD_LIBRARY_PATH=usr/lib

trap clean_up SIGHUP SIGINT SIGTERM
scripts/create_gfx.sh

while [ 1 == 1 ]; do
	scripts/init.sh
	./toxblinkenwall
	sleep 10
done

