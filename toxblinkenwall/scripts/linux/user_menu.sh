#! /bin/bash

function enter_qrcode()
{
    echo "################################"
    echo "################################"
    echo "################################"
    echo "################################"
    echo "################################"
    echo "################################"
    echo ""
    echo ""
    echo "     hold QR code to camera     "
    echo ""
    echo ""
    echo ""

    . $(dirname "$0")/vars.sh

    echo ""
    echo "  using camera: $video_device"
    echo ""

    echo -n '  starting in 6 seconds '
    for _ in {1..6}; do
        sleep 1
        echo -n '.'
    done
    echo ""

    ZBAR_STDOUT=$(mktemp)
    ZBAR_STDERR=$(mktemp)

    zbarcam --raw --nodisplay "$video_device" > "$ZBAR_STDOUT" 2> "$ZBAR_STDERR" &

    while :
    do
        read -r -t 0.2 -n 1 key

        if [ "$key""x" == "q""x" ]; then
            # exit due key event
            reason="key"
            break
        fi

        if [ -s "$ZBAR_STDOUT" ]; then
            cat "$ZBAR_STDOUT" 2>/dev/null | \
                tr -cd '[a-zA-Z0-9]' 2>/dev/null | \
                tr '[:lower:]' '[:upper:]' > "/tmp/qrcode.txt" 2>/dev/null
            reason="scan"
            break
        fi

        # check if zbarcam is still running
        pgrep -f zbarcam >/dev/null 2> /dev/null
        res_running=$?
        if [ $res_running -eq 0 ]; then
            :
        else
            # exit due to zbar error
            # cat "$ZBAR_STDERR"
            reason="subprocess_exit"
            break
        fi
    done

    rm -f "$ZBAR_STDOUT"
    rm -f "$ZBAR_STDERR"

    pkill -f zbarcam 2>/dev/null
    pkill -9 -f zbarcam 2>/dev/null
}

function func_addfriend()
{
	CHOICE=$(dialog --menu "ToxBlinkenwall - add Friend" 0 0 0 \
		Scan "show me a QR Code" \
		Enter "ToxID manually" \
		Cancel "" \
		3>&1 1>&2 2>&3 )

    res2=$?
    clear

    # Return status of non-zero indicates cancel
    if [ $res2 != 0 ]; then
        CHOICE="Cancel"
    fi

    clear

	case $CHOICE in
		Scan)
			QRCODE=""

            rm -f "/tmp/qrcode.txt"
			enter_qrcode
            if [ -s "/tmp/qrcode.txt" ]; then
                QRCODE=$(cat "/tmp/qrcode.txt" 2>/dev/null | tr -cd '[a-zA-Z0-9]' 2>/dev/null | tr '[:lower:]' '[:upper:]' 2>/dev/null )
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_8.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_9.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_7.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_8.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_6.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_7.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_5.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_6.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_4.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_5.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_3.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_4.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_2.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_3.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_1.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_2.txt"
                echo "$QRCODE" > "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_1.txt"
			else
				dialog --msgbox "ERROR scanning qrcode from camera" 0 0
			fi
            rm -f "/tmp/qrcode.txt"
			;;
		Enter)
			tmp_toxid=$(mktemp)
			if dialog --inputbox "Please enter QR Code, like this: 12345890ABCDEF" 0 0 2>"$tmp_toxid"
			then
                QRCODE=$(cat "$tmp_toxid" 2>/dev/null | tr -cd '[a-zA-Z0-9]' 2>/dev/null | tr '[:lower:]' '[:upper:]' 2>/dev/null )
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_8.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_9.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_7.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_8.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_6.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_7.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_5.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_6.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_4.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_5.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_3.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_4.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_2.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_3.txt"
                cp "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_1.txt" "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_2.txt"
                echo "$QRCODE" > "/home/pi/ToxBlinkenwall/toxblinkenwall/book_entry_1.txt"
			else
				dialog --msgbox "ERROR entering qrcode" 0 0
			fi
			rm -f $tmp_toxid
			;;
		Cancel)
			return
			;;
	esac
}


function func_start() {
    echo "##############################"
    echo "##############################"
    echo "##############################"
    echo "##############################"
    echo ""
    echo ""
    echo ""
    echo "-- starting ToxBlinkenwall --"
    echo ""
    echo ""
    echo ""

    $(dirname "$0")/../initscript.sh start &
    exit
}

function func_shutdown() {
    sudo /sbin/shutdown now
}

function func_exit() {
    # pwd
    # echo $(dirname "$0")
    echo "##############################"
    echo "##############################"
    echo "##############################"
    echo "##############################"
    echo ""
    echo ""
    echo ""
    echo "         -- EXIT --"
    echo ""
    echo ""
    echo ""
    exit
}

while : ; do

    clear

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
            # echo "start ....."
            func_start
            ;;
        Add)
            # echo "phonebook_menu"
            func_addfriend
            # --> this will continue to the main menu
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

done

clear # but we should never get here
