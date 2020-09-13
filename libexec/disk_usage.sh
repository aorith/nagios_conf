#!/bin/bash

[ $# -ne 2 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
MOUNT=$2

output="$(ssh "aorith@${SERVER}" "df -BM --output=fstype,itotal,iused,iavail,ipcent,used,avail,pcent,size $MOUNT |tail -1")"

fstype="$(echo "$output"|awk '{ print $1 }')"
itotal="$(echo "$output"|awk '{ print $2 }')"
iused="$(echo "$output"|awk '{ print $3 }')"
iavail="$(echo "$output"|awk '{ print $4 }')"
ipcent="$(echo "$output"|awk '{ print $5 }')"
used="$(echo "$output"|awk '{ print $6 }')"
avail="$(echo "$output"|awk '{ print $7 }')"
pcent="$(echo "$output"|awk '{ print $8 }')"
size="$(echo "$output"|awk '{ print $9 }')"

#perfdata
echo -n "|"
echo -n "Used=${used};;;;"
echo -n "Total=${size};;;;"
echo "Percent=${pcent},Total=${size};90;95;;"

exit $EXITCODE
