#! /bin/bash

#*********************************
#
# ToxBlinkenwall - init script
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

cmd_grep='loop_services.sh'
cmd_grep2='toxblinkenwall'

procs="$(pgrep -f "$cmd_grep")"

# to really have VARs also when run from sudo
cd
. .profile

command="$1"

if [ "$command""x" == "startx" ]; then
	if [ "$procs""x" == "x" ];then
		cd ~/ToxBlinkenwall/toxblinkenwall/
		./loop_services.sh > /dev/null 2>/dev/null &
	fi
	echo "running"
else
	for p in $(pgrep -f "$cmd_grep");do
		echo kill $p
		kill $p
	done

	sleep 10
	for p in $(pgrep -f "$cmd_grep2");do
		echo kill $p
		kill $p
	done
	echo "stopped"
fi
