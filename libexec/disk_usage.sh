#!/bin/bash

[ $# -ne 2 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
MOUNT=$2

output="$(ssh "aorith@${SERVER}" "df -BK --output=fstype,itotal,iused,iavail,ipcent,used,avail,pcent,size $MOUNT |tail -1")"

fstype="$(echo "$output"|awk '{ print $1 }')"
itotal="$(echo "$output"|awk '{ print $2 }')"
iused="$(echo "$output"|awk '{ print $3 }')"
iavail="$(echo "$output"|awk '{ print $4 }')"
ipcent="$(echo "$output"|awk '{ print $5 }')"
used="$(echo "$output"|awk '{ print $6 }')"
avail="$(echo "$output"|awk '{ print $7 }')"
pcent="$(echo "$output"|awk '{ print $8 }')"
size="$(echo "$output"|awk '{ print $9 }')"

echo -n "$output"
#perfdata
echo -n "|"
echo "disk_used=${used};;;; disk_total=${size};;;; percent=${pcent};90;95;;"

exit $EXITCODE
