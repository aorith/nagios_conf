#!/bin/bash

[ $# -ne 1 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1

last_entry_date="$(ssh "aorith@${SERVER}" "sadf -dt -- -b |cut -d';' -f3|tail -1")"
output="$(ssh "aorith@${SERVER}" "sadf -dt -- -b |grep \"${last_entry_date}\"")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

# hostname;interval;timestamp;tps;rtps;wtps;bread/s;bwrtn/s
# 0        1        2         3   4    5    6       7
# pve;60;2020-09-15 00:01:01;72.65;39.63;33.03;2160.71;820.66

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

tps=${ARR[3]}
rtps=${ARR[4]}
wtps=${ARR[5]}
bread_s=$(echo "${ARR[6]} * 512" |bc)
bwrtn_s=$(echo "${ARR[7]} * 512" |bc)

text="$tps tps - $rtps rtps - $wtps wtps - $bread_s bread/s - $bwrtn_s bwrtn/s"
perfdata="tps=${tps};;;0; rtps=${rtps};;;0; wtps=${wtps};;;0; bread_s=${bread_s};;;0; bwrtn_s=${bwrtn_s};;;0;"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
