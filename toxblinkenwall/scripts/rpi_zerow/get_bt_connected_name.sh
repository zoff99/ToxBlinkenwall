#! /bin/bash

connectedDev=$(hcitool con 2>/dev/null)
conMac=${connectedDev:20:18}
conMac=$(echo "$conMac" 2>/dev/null|tr -d " " 2>/dev/null)
conname=$(hcitool name "$conMac" 2>/dev/null)
echo "$conname" 2>/dev/null
