#! /bin/bash

cpu1=$(</sys/class/thermal/thermal_zone0/temp)
cpu_int=$((cpu1/1000))

echo $cpu_int
