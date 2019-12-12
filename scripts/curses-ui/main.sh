#!/bin/bash -ex

cd $(dirname $0) # Change working directory

. ./add.sh

main()
{
	while : ; do

	CHOICE=$(dialog --menu "$(hostname)" 20 100 10 \
		Start "ToxBlinkenwall" \
		Add "a new friend by ToxID" \
		Shell "OS Shell" \
		Shutdown "poweroff" \
		Exit "" \
		3>&1 1>&2 2>&3 )

	case $CHOICE in
		Start)
			#~/ToxBlinkenwall/toxblinkenwall/initscript.sh start
			cd ~/ToxBlinkenwall/toxblinkenwall/
			~/ToxBlinkenwall/toxblinkenwall/toxblinkenwall
			wait && main
			;;
		Add)
			phonebook_menu
			;;
		Kill*)
			killall t_main
			;;
		Shell)
			bash
			;;
		Info)
			. menu/info.sh
			;;
		Shutdown)
			systemctl poweroff
			;;
		Exit)
			exit
			;;
		*)
			;;
	esac

	done
}

if [ -z "$1" ]; then
	main
else
	eval $@
fi
