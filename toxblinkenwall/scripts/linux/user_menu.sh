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

function func_start() {
    $(dirname "$0")/../initscript start &
    exit
}

function func_shutdown() {
    sudo shutdown now
}

function func_exit() {
    # pwd
    # echo $(dirname "$0")
    echo "exit"
    exit
}

case $CHOICE in
    Start)
        # echo "start ....."
        func_start
        ;;
    Add)
        # echo "phonebook_menu"
        func_addfriend
        ;;
    Shutdown)
        # echo "shutdown"
        func_shutdown
        ;;
    Exit)
        # echo "exit"
        func_exit
        ;;
    *)
        # echo "++default++"
        func_exit
        ;;
esac

