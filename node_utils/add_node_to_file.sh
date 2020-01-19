#! /bin/bash

outfile="./nodes_file.bin"

ip_=$(echo "$1"|cut -d';' -f 1)
port_=$(echo "$1"|cut -d';' -f 2)
dht_key_=$(echo "$1"|cut -d';' -f 3 | tr '[:lower:]' '[:upper:]' )
tcp_=$(echo "$1"|cut -d';' -f 4)

./ip2binary.pl "$ip_" >> "$outfile"
./port2binary.pl "$port_" >> "$outfile"
./hex2bin.pl "$dht_key_" >> "$outfile"

if [ "$tcp_""x" == "1x" ]; then
    printf '\1' >> "$outfile"
else
    printf '\0' >> "$outfile"
fi

# hexdump -C "$outfile"

