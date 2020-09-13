#!/bin/bash

[ $# -ne 4 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
MOUNT=$2
WARN=$3
CRIT=$4

output="$(ssh "aorith@${SERVER}" "df -k --output=fstype,itotal,iused,iavail,ipcent,used,avail,pcent,size $MOUNT |tail -1")"

fstype="$(echo "$output"|awk '{ print $1 }')"
itotal="$(echo "$output"|awk '{ print $2 }')"
iused="$(echo "$output"|awk '{ print $3 }')"
iavail="$(echo "$output"|awk '{ print $4 }')"
ipcent="$(echo "$output"|awk '{ print $5 }')"
used="$(echo "$output"|awk '{ print $6 }')"
avail="$(echo "$output"|awk '{ print $7 }')"
pcent="$(echo "$output"|awk '{ print $8 }')"
size="$(echo "$output"|awk '{ print $9 }')"

status=0
[[ ${pcent%%%} -ge $WARN ]] && status=1
[[ ${pcent%%%} -ge $CRIT ]] && status=2

echo -n "$output"
#perfdata
echo -n "|"
echo "used=${used}KB;;${size}; percent=${pcent};90;95;;"

exit $status
