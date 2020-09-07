#! /bin/bash

# set realtime prio to this "TID"
sudo chrt -f -p 99 "$1"
