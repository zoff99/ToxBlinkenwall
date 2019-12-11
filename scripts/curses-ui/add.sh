#!/bin/bash -ex

. ./zbar.sh

height=20
width=100

function add_friend()
{
	index=$1

	CHOICE=$(dialog --menu "$(hostname)" 20 100 10 \
		Show\) "me a QR Code" \
		Enter\) "ToxID manually" \
		Cancel\) "" \
		3>&1 1>&2 2>&3 )
	case $CHOICE in
		Show*)
			QRCODE=""
			enter_qrcode QRCODE
			if $? ; then
				CHOICE=$(dialog --inputbox "text" $height $width \
					"Got QR Code. Save as Friend #$index?" \
					 "$QRCODE" \
					 )
			else
				dialog --msgbox "ERROR! \n $QRCODE" $height $width
			fi
			;;
		Exit*)
			return
			;;
		*)
			add_friend $CHOICE
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
		*)
			add_friend $CHOICE
			;;
	esac
}
