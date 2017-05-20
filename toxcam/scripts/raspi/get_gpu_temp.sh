#! /bin/bash

gpu1=$(/opt/vc/bin/vcgencmd measure_temp)
gpu=$(echo "$gpu1"|sed -e 's#^.*=##'|sed -e 's#.C.*$##')
# gpu_int=$(echo "$gpu1"|sed -e 's#^.*=##'|sed -e 's#\..*$##')

echo $gpu
