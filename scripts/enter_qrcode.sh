#!/bin/bash

ZBAR_STDOUT=$(mktemp)
ZBAR_STDERR=$(mktemp)

#(zbarcam --nodisplay > $FIFO) &
(zbarcam --raw --nodisplay > $ZBAR_STDOUT 2> $ZBAR_STDERR) &
zbar_pid=$!

while :
do
    # TASK 1
    read -t 0.2 -n 1 key

    if [[ $key = q ]]
    then
        #echo exit due key event
        break
    fi
    
    QRCODE=$(cat "$ZBAR_STDOUT")
    
    # just assume it's a valid ToxID

    if [[ ! $QRCODE = "" ]]
    then
        #echo exit due scan event
        break
    fi

    # check if zbarcam is still running
    if kill -s 0 $zbar_pid
    then
        :
    else 
        #echo exit due to zbar error
        cat $ZBAR_STDERR
        break
    fi
done

echo $QRCODE

rm -f $ZBAR_STDOUT $ZBAR_STDERR
#kill $zbar_pid
pkill zbarcam
wait
