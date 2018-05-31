#! /bin/bash

fifo="../ext_keys.fifo"

while [ true ]; do
	cat "$fifo"
done
