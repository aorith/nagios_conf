#!/bin/bash

[ $# -ne 2 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
IFACE=$2

last_entry_date="$(ssh "aorith@${SERVER}" "sadf -dt -- -n DEV --iface=$IFACE |cut -d';' -f3|tail -1")"
output="$(ssh "aorith@${SERVER}" "sadf -dt -- -n DEV --iface=$IFACE |grep \"${last_entry_date}\"")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

## hostname;interval;timestamp;IFACE;rxpck/s;txpck/s;rxkB/s;txkB/s;rxcmp/s;txcmp/s;rxmcst/s;%ifutil
#pve;120;2020-09-14 08:28:01;enp6s0f0;38.71;20.18;36.08;2.08;0.00;0.00;0.31;0.03

status=0
old_IFS=$IFS
IFS=';'
count=0
ARR=()
for field in $output;
do
    ARR[$count]="$field"
    count=$(( count + 1 ))
done
IFS=$old_IFS

re='[0-9\.]+'
[[ ! ${ARR[4]} =~ $re ]] && { echo "Error reading sadf(sar) output."; exit 3; }

text="${ARR[3]} rxKB/s ${ARR[7]} txKB/s ${ARR[8]} Usage ${ARR[11]}"
perfdata="rxKBs_s=${ARR[7]}KB;;;0; txKBs_s=${ARR[8]}KB;;;0; Usage_perc=${ARR[11]}%;;;0;100"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
