#! /bin/bash

##### -------------------------------------
# pick first available framebuffer device
# change for your needs here!
export fb_device=$(ls -1 /dev/fb*|head -1)
##### -------------------------------------

##### -------------------------------------
export FB_WIDTH=640
export FB_HEIGHT=480

if [ "$IS_ON""x" == "RASPI""x" ]; then
  export BKWALL_WIDTH=640
  export BKWALL_HEIGHT=480
elif [ "$IS_ON""x" == "BLINKENWALL""x" ]; then
  export BKWALL_WIDTH=192
  export BKWALL_HEIGHT=144
fi

if [ "$HD""x" == "RASPIHD""x" ]; then
  export BKWALL_WIDTH=1280
  export BKWALL_HEIGHT=720
  export FB_WIDTH=1280
  export FB_HEIGHT=720
fi

# TODO: dont hardcode "fb0" here!!
stride_=$(cat /sys/class/graphics/fb0/stride)
bits_per_pixel_=$(cat /sys/class/graphics/fb0/bits_per_pixel)
virtual_size=$(cat /sys/class/graphics/fb0/virtual_size)
# TODO: dont hardcode "fb0" here!!

if [[ $bits_per_pixel_ -lt 8 ]]; then
  # TODO: the result will be wrong, but its not DIV by zero error!
  tmp1=1
  export FB_WIDTH=640
  export FB_HEIGHT=480
  export BKWALL_WIDTH=640
  export BKWALL_HEIGHT=480
else
  tmp1=$[ $bits_per_pixel_ / 8 ]
fi

export real_width=$[ $stride_ / $tmp1 ]
##### -------------------------------------

#####################################################
# pick last available video device
# change for your needs here!
export video_device=$(ls -1 /dev/video*|tail -1)
#
#####################################################
