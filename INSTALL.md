#### Install on the Blinkenwall


```
# TODO: this needs to be tweaked a bit
ToxBlinkenwall/toxblinkenwall/_install_linux_X.sh

# echo 'default_driver=alsa
# verbose=true
# ' > $_HOME_/.libao

# audio test program
gcc a.c -lao -ldl -lm -o a

cd $_HOME_
ln -s ToxBlinkenwall/toxblinkenwall/initscript.sh

echo 'IS_ON=BLINKENWALL
export IS_ON
' >> $_HOME_/.profile
```

#### Install on the RaspberryPI


```
ToxBlinkenwall/toxblinkenwall/_install_raspi.sh

echo 'IS_ON=RASPI
export IS_ON
' >> $_HOME_/.profile
```

and if you want 720p video resolution add:

```
echo 'HD=RASPIHD
export HD
' >> $_HOME_/.profile
```

if your screen turns off after 10 minutes do this:

```
sudo nano /etc/lightdm/lightdm.conf

# add to the [Seat:*] section
xserver-command=X -s 0 dpms

# now save and reboot the pi!
```


#### overclock settings

```
arm_freq=1350
over_voltage=5
temp_limit=79

gpu_mem=400
core_freq=500
gpu_freq=450

sdram_freq=450
sdram_schmoo=0x02000020
over_voltage_sdram_p=6
over_voltage_sdram_i=4
over_voltage_sdram_c=4
```


#### Install on the Linux with X11 Server


```
ToxBlinkenwall/toxblinkenwall/_install_linux_X.sh

echo 'IS_ON=RASPI
export IS_ON
' >> $_HOME_/.profile
```

