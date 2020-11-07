#!/bin/bash
LC_ALL=C

[ $# -ne 1 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -q 1 3 |grep 'Average:'")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

status=0
count=0
ARR=()
for field in $output;
do
    ARR[$count]="$field"
    count=$(( count + 1 ))
done

# 09:00:54 AM   runq-sz  plist-sz   ldavg-1   ldavg-5  ldavg-15   blocked
# Average:            0       227      0.44      0.36      0.24         0
#  0                  1       2        3         4         5            6

re='[0-9\.]+'
if [[ ! ${ARR[4]} =~ $re ]]; then
    echo "Error reading sadf(sar) output."
    exit 3
fi

run_queue_length=${ARR[1]}
tasks=${ARR[2]}
load1=${ARR[3]}
load5=${ARR[4]}
load15=${ARR[5]}
blocked=${ARR[6]}

nprocs=$(ssh "aorith@${SERVER}" "nproc")
perc_load1=$(echo "scale=2; (${load1}*100)/${nprocs}" |bc -l)
WARN=$(echo "scale=3;0.5 * $nprocs" |bc -l)
CRIT=$(echo "scale=3;0.7 * $nprocs" |bc -l)

echo "$perc_load1 > 70" | bc && status=1
echo "$perc_load1 > 90" | bc && status=2

text="load1(%) ${perc_load1}% - load(1/5/15)m ${load1}/${load5}/${load15} - RunQueueLength $run_queue_length - Tasks $tasks - Blocked $blocked"
perfdata="load1=${load1};$WARN;$CRIT;0; load5=${load5};$WARN;$CRIT;0; load15=${load15};$WARN;$CRIT;0; run_queue_length=${run_queue_length};10;30;0; tasks=${tasks};;;0; blocked=${blocked};1;5;0; perc_load1=${perc_load1}%;50;80;0;"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
