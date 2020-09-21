#!/bin/bash

[ $# -ne 1 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1

last_entry_date="$(ssh "aorith@${SERVER}" "sadf -dt -- -q |cut -d';' -f3|tail -1")"
output="$(ssh "aorith@${SERVER}" "sadf -dt -- -q |grep \"${last_entry_date}\"")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

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

# hostname;interval;timestamp;runq-sz;plist-sz;ldavg-1;ldavg-5;ldavg-15;blocked
# 0        1        2         3       4        5       6       7        8
#pve;60;2020-09-15 00:01:01;0;715;0.44;0.32;0.28;2

re='[0-9\.]+'
if [[ ! ${ARR[4]} =~ $re ]]; then
    # exit if first field is an '#' that means we have no data after rotate
    [[ ${ARR[0]} == "#" ]] && exit 0
    echo "Error reading sadf(sar) output."
    exit 3
fi

run_queue_length=${ARR[3]}
tasks=${ARR[4]}
load1=${ARR[5]}
load5=${ARR[6]}
load15=${ARR[7]}
blocked=${ARR[8]}

nprocs=$(ssh "aorith@${SERVER}" "nproc")
perc_load1=$(echo "scale=2; (${load1}*100)/${nprocs}" |bc)
WARN=$(echo "scale=3;0.5 * $nprocs" |bc)
CRIT=$(echo "scale=3;0.7 * $nprocs" |bc)

text="load1(%) ${perc_load1}% - load(1/5/15)m ${load1}/${load5}/${load15} - RunQueueLength $run_queue_length - Tasks $tasks - Blocked $blocked"
perfdata="load1=${load1};$WARN;$CRIT;0; load5=${load5};$WARN;$CRIT;0; load15=${load15};$WARN;$CRIT;0; run_queue_length=${run_queue_length};10;30;0; tasks=${tasks};;;0; blocked=${blocked};1;5;0; perc_load1=${perc_load1}%;50;80;0;"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
