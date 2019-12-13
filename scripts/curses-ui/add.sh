#!/bin/bash -ex

. ./zbar.sh

height=20
width=100

function write_qrcode() {
	qrcode="$1"
	index=$2

	path="$(realpath ~/ToxBlinkenwall/toxblinkenwall/book_entry_$index.txt)"

	if [ ! -f "$path" ]; then
		error "$path:" file not found
		return
	fi

	echo "$qrcode" > "$path"
}

function add_friend()
{
	index=$1

	CHOICE=$(dialog --menu "$(hostname)" 20 100 10 \
		Scan\) "show me a QR Code" \
		Enter\) "ToxID manually" \
		Cancel\) "" \
		3>&1 1>&2 2>&3 )
	case $CHOICE in
		Scan*)
			QRCODE=""
			
			if enter_qrcode QRCODE ; then
				tmp_toxid=$(mktemp)
				if dialog --inputbox "Got QR Code. Save as Friend #$index?" $height $width \
					 "$QRCODE" 2>$tmp_toxid
				then
					write_qrcode "$(<$tmp_toxid)" $index
				else
					dialog --msgbox "Abort" $height $width
				fi
				rm $tmp_toxid
			else
				dialog --msgbox "ERROR $?\n $QRCODE" $height $width
			fi
			;;
		Enter*)
			tmp_toxid=$(mktemp)
			if dialog --inputbox "Please enter QR Code, like this: 12345890ABCDEF for #$index?" $height $width 2>$tmp_toxid
			then
				write_qrcode "$(<$tmp_toxid)" $index
			else
				dialog --msgbox "Abort" $height $width
			fi
			rm $tmp_toxid
			;;
		Cancel*)
			return
			;;
	esac
}

function phonebook_menu()
{
	CHOICE=$(dialog --menu "$(hostname)" 20 100 10 \
		1\) "Phonebook Slot #1" \
		2\) "$PHONEBOOK_SLOT2" \
		Back\) "To Main Menu" \
		3>&1 1>&2 2>&3 )

	case $CHOICE in
		Back)
			;;
		1*)
			add_friend 1
			;;
	esac
}
