#! /bin/bash

# thanks to:
# https://github.com/Roggerson/BluetoothPlayer/blob/master/scripts/bash/checkDevCon.sh

connectedDev=$(hcitool con 2>/dev/null)
conMac=${connectedDev:20:18}
conMac=$(echo "$conMac" 2>/dev/null|tr -d " " 2>/dev/null)
echo "$conMac" 2>/dev/null
