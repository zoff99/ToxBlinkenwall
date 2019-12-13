#! /bin/bash

# . $(dirname "$0")/vars.sh

CHOICE=$(dialog --cancel-label "Start" \
--default-item "Add" \
--menu "ToxBlinkenwall - Main Menu" \
0 0 0 \
Start "ToxBlinkenwall" \
Add "a friend by ToxID" \
Shutdown "System" \
Exit "" \
3>&1 1>&2 2>&3 )

res=$?
clear

# Return status of non-zero indicates cancel
if [ $res != 0 ]; then
    CHOICE="Start"
fi

case $CHOICE in
    Start)
        echo "start ....."
        ;;
    Add)
        echo "phonebook_menu"
        ;;
    Shutdown)
        echo "shutdown"
        ;;
    Exit)
        echo "exit"
        ;;
    *)
        echo "++default++"
        ;;
esac

