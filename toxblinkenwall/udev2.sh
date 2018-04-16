#! /bin/bash

usb_device="$1"
mount_dir="/usb_device___/"
entry_1="book_entry_1.txt"
entry_2="book_entry_2.txt"
dst_dir=$(dirname "$0")
logfile="$dst_dir""/tox_usbmount.log"

touch "$logfile"
chmod a+rw "$logfile" 2> /dev/null

# full device
mkdir -p "$mount_dir"
echo "mounting $usb_device ..." >> "$logfile"
mount "$usb_device" "$mount_dir" >> "$logfile" 2>&1

if [ -e "$mount_dir""/""$entry_1" ]; then
        ls -al "$mount_dir""$entry_1" >> "$logfile"
        cp -v "$mount_dir""$entry_1" "$dst_dir""/" >> "$logfile" 2>&1
        chmod a+rw "$dst_dir""/""$entry_1"
fi

if [ -e "$mount_dir""/""$entry_2" ]; then
        ls -al "$mount_dir""$entry_2" >> "$logfile"
        cp -v "$mount_dir""$entry_2" "$dst_dir""/" >> "$logfile" 2>&1
        chmod a+rw "$dst_dir""/""$entry_2"
fi

echo "UNmounting $usb_device ..." >> "$logfile"
umount "$mount_dir" >> "$logfile" 2>&1
rmdir "$mount_dir"

# first partition
mkdir -p "$mount_dir"
echo "mounting $usb_device""1"" ..." >> "$logfile"
mount "$usb_device""1" "$mount_dir" >> "$logfile" 2>&1

if [ -e "$mount_dir""/""$entry_1" ]; then
        ls -al "$mount_dir""$entry_1" >> "$logfile"
        cp -v "$mount_dir""$entry_1" "$dst_dir""/" >> "$logfile" 2>&1
        chmod a+rw "$dst_dir""/""$entry_1"
fi

if [ -e "$mount_dir""/""$entry_2" ]; then
        ls -al "$mount_dir""$entry_2" >> "$logfile"
        cp -v "$mount_dir""$entry_2" "$dst_dir""/" >> "$logfile" 2>&1
        chmod a+rw "$dst_dir""/""$entry_2"
fi


echo "UNmounting $usb_device""1"" ..." >> "$logfile"
umount "$mount_dir" >> "$logfile" 2>&1
rmdir "$mount_dir"
