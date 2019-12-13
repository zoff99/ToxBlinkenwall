#! /bin/bash

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

function enter_qrcode()
{
    ZBAR_STDOUT=$(mktemp)
    ZBAR_STDERR=$(mktemp)

    . $(dirname "$0")/vars.sh

    coproc ZBAR { zbarcam --raw --nodisplay "$video_device" ; }

    ZBAR_STDOUT="/tmp/xxxx""$$" # because we rm it later, just in case do not leave it empty

    zbar_pid=$ZBAR_PID

    while :
    do
        # TASK 1
        read -r -t 0.2 -n 1 key

        if [[ "$key""x" == "q""x" ]]
        then
            #echo exit due key event
            reason="key"
            break
        fi

        read -r -t 0.2 QRCODE <&${ZBAR[0]} # https://unix.stackexchange.com/a/354604
        #QRCODE=$(head -n 1 "$ZBAR_STDOUT")

        # just assume it's a valid ToxID
        if [[ ! "$QRCODE""x" == """x" ]]
        then
            # return result via qrcode parameter
            # great potential for funny qrcode exploits ;D
            # source:
            # https://stackoverflow.com/a/3243034

            eval "$1='$QRCODE'" # TODO: please someone escape this sh*t correctly
            reason="scan"
            break
        fi

        # check if zbarcam is still running
        if kill -s 0 $zbar_pid
        then
            :
        else
            #echo exit due to zbar error
            cat "$ZBAR_STDERR"
            reason="subprocess_exit"
            break
        fi
    done

    if [ "$reason""x" == "subprocess_error""x" ]; then
        # this might happen in display mode, when pressing 'q'
        # or on actual erros. try to return error code in this case
        cat "$ZBAR_STDERR" 1>&2
        wait $zbar_pid 2>/dev/null
        ret=$?
    else
        kill -9 $zbar_pid
        wait $zbar_pid 2>/dev/null
    fi
    rm -f "$ZBAR_STDOUT" "$ZBAR_STDERR"
    pkill zbarcam

    [ "$reason""x" == "key""x" ] || [ ! "$QRCODE""x" == "0""x" ] && ret=0

    return "$ret"
}


function write_qrcode() {
	echo "$1" > "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_1.txt"
}

function func_addfriend()
{
	CHOICE=$(dialog --menu "ToxBlinkenwall - add Friend" 0 0 0 \
		Scan\) "show me a QR Code" \
		Enter\) "ToxID manually" \
		Cancel\) "" \
		3>&1 1>&2 2>&3 )

	case $CHOICE in
		Scan*)
			QRCODE=""
			
			if enter_qrcode QRCODE ; then
				tmp_toxid=$(mktemp)
				if dialog --inputbox "Got QR Code. Save as Friend" 0 0 \
					 "$QRCODE" 2>"$tmp_toxid"
				then
					write_qrcode "$(<$tmp_toxid)"
				else
					dialog --msgbox "Abort" 0 0
				fi
				rm -f "$tmp_toxid"
			else
				dialog --msgbox "ERROR $?\n $QRCODE" 0 0
			fi
			;;
		Enter*)
			tmp_toxid=$(mktemp)
			if dialog --inputbox "Please enter QR Code, like this: 12345890ABCDEF for #$index?" 0 0 2>"$tmp_toxid"
			then
				write_qrcode "$(<$tmp_toxid)"
			else
				dialog --msgbox "Abort" 0 0
			fi
			rm -f $tmp_toxid
			;;
		Cancel*)
			return
			;;
	esac
}


function func_start() {
    $(dirname "$0")/../initscript start &
    exit
}

function func_shutdown() {
    sudo /sbin/shutdown now
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

