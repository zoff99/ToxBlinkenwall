#! /bin/bash

pid=$(pgrep -f toxblinkenwall -w) # multipile results
realtime=1
level=1

if [ "$pid""x" == "x" ]; then
	exit 1
fi

sudo renice -n -20 -p $pid
sudo ionice -c $realtime -n "$level" -p $pid
