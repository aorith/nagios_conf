#!/bin/bash
LC_ALL=C

[ $# -ne 1 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -b 1 3 |grep 'Average:'")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

# 08:29:53 AM       tps      rtps      wtps   bread/s   bwrtn/s
# 08:29:56 AM      0.00      0.00      0.00      0.00      0.00
# Average:         0.00      0.00      0.00      0.00      0.00
#  0                1         2         3         4         5

status=0
count=0
ARR=()
for field in $output;
do
    ARR[$count]="$field"
    count=$(( count + 1 ))
done

re='[0-9\.]+'
if [[ ! ${ARR[1]} =~ $re ]]; then
    echo "Error reading sadf(sar) output."
    exit 3
fi

tps=${ARR[1]}
rtps=${ARR[2]}
wtps=${ARR[3]}
bread_s=$(echo "${ARR[4]} * 512" |bc)
bwrtn_s=$(echo "${ARR[5]} * 512" |bc)

text="$tps tps - $rtps rtps - $wtps wtps - $bread_s bread/s - $bwrtn_s bwrtn/s"
perfdata="tps=${tps};;;0; rtps=${rtps};;;0; wtps=${wtps};;;0; bread_s=${bread_s};;;0; bwrtn_s=${bwrtn_s};;;0;"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
