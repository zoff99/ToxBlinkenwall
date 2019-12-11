#!/bin/bash


function enter_qrcode()
{
    ZBAR_STDOUT=$(mktemp)
    ZBAR_STDERR=$(mktemp)

    (zbarcam --raw > $ZBAR_STDOUT 2> $ZBAR_STDERR) &
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
        
        QRCODE=$(head -n 1 "$ZBAR_STDOUT")
        
        # just assume it's a valid ToxID
        if [[ ! $QRCODE = "" ]]
        then
            # return result via qrcode parameter
            eval "$1='\"$QRCODE\"'"
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

    #echo $QRCODE

    cat $ZBAR_STDERR 1>&2
    kill $zbar_pid
    wait $zbar_pid
    ret=$?
    rm -f $ZBAR_STDOUT $ZBAR_STDERR
    pkill zbarcam
    return $?
}
