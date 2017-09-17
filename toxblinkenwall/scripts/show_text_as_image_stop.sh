#! /bin/bash

if [ "$IS_ON""x" == "RASPI""x" ]; then
    :
else

# stop openGL text stuff -----
node /usr/local/blinkenwall/poetry/restart.js
# stop openGL text stuff -----

fi
