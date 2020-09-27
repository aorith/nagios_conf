#!/bin/bash
LC_ALL=C

[ $# -ne 3 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }
SERVER=$1
WARN=$2
CRIT=$3
WARN_C=$WARN
CRIT_C=$CRIT

if ssh "aorith@${SERVER}" "sudo grep -qa container=lxc /proc/1/environ"; then
    WARN_C=$(echo "scale=2; $WARN * 100" |bc -l)
    CRIT_C=$(echo "scale=2; $CRIT * 100" |bc -l)
fi

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -r ALL 1 3 |grep 'Average:'")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

status=0
count=0
ARR=()
for field in $output;
do
    ARR[$count]="$field"
    count=$(( count + 1 ))
done

re='[0-9\.]+'
if [[ ! ${ARR[4]} =~ $re ]]; then
    echo "Error reading sadf(sar) output."
    exit 3
fi

# sar -r ALL
# 10:11:43 AM kbmemfree   kbavail kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty  kbanonpg    kbslab  kbkstack   kbpgtbl  kbvmused
# Average:      1088928   1655924    264200     12.96     63792    456152    584800      8.06    444724    280328         4    205184    165168      1904      2120     18108
# 0             1           2           3       4           5       6           7        8       9          10         11       12         13        14        15        16

kbmemfree=${ARR[1]}
kbavail=${ARR[2]}
kbmemused=${ARR[3]}
memused_perc=${ARR[4]}
kbbuffers=${ARR[5]}
kbcached=${ARR[6]}
kbcommit=${ARR[7]}
commit_perc=${ARR[8]}

text="MemUsed:${memused_perc}% - Commited:${commit_perc}%"
perfdata="kbmemfree=${kbmemfree}KB;;;0; kbavail=${kbavail}KB;;;0; kbmemused=${kbmemused}KB;;;0; memused_perc=${memused_perc}%;$WARN;$CRIT;0; kbbuffers=${kbbuffers}KB;;;0; kbcached=${kbcached}KB;;;0; kbcommit=${kbcommit}KB;;;0; commit_perc=${commit_perc}%;$WARN_C;$CRIT_C;0;"

# testing if $1 > $2
_decimal_compare() {
    [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]
}

if _decimal_compare $memused_perc $CRIT || _decimal_compare $commit_perc $CRIT_C; then 
    status=2
    text="CRITICAL: ${text}"
elif _decimal_compare $memused_perc $WARN || _decimal_compare $commit_perc $WARN_C; then 
    status=1
    text="WARNING: ${text}"
fi

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
