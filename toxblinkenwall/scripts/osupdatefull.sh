#! /bin/bash

function background
{
    sleep 20

    # unattended OS update
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical
    sudo -E apt-get -qy update
    sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" \
         -o "Dpkg::Options::=--force-confold" upgrade
    sudo -E apt-get -qy autoclean

    # now reboot
    sudo shutdown -r now
}

background >/dev/null </dev/null &

