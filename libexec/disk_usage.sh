#!/bin/bash

[ $# -ne 4 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
MOUNT=$2
WARN=$3
CRIT=$4

# testing if $1 > $2
_decimal_compare() {
    [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]
}

output="$(ssh "aorith@${SERVER}" "sadf -dht -- -F MOUNT --fs=$MOUNT 1 1|tail -1")"

## hostname;interval;timestamp          ;MOUNTPOINT;MBfsfree;MBfsused;%fsused;%ufsused;Ifree ;Iused;%Iused
# nagios   ;120     ;2020-09-14 08:28:01;/         ;5400    ;2600    ;32.50  ;37.82   ;459151;65137;12.42
#  0        1        2                   3          4        5        6       7        8      9     10

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

re='[0-9]+'
[[ ! ${ARR[4]} =~ $re ]] && { echo "Error reading sadf(sar) output."; exit 3; }

status=0
msg="OK:"
if _decimal_compare ${ARR[10]} $WARN; then status=1; msg="WARNING:"; fi
if _decimal_compare ${ARR[10]} $CRIT; then status=2; msg="CRITICAL:"; fi
if _decimal_compare ${ARR[6]} $WARN; then status=1; msg="WARNING:"; fi
if _decimal_compare ${ARR[6]} $CRIT; then status=2; msg="CRITICAL:"; fi

total=$(echo "${ARR[4]} + ${ARR[5]}" |bc )

echo -n "$msg ${ARR[3]} ${ARR[5]}MB/${total}MB(${ARR[6]}%) - Iused:${ARR[9]}(${ARR[10]}%)"
#perfdata
echo -n "|"
echo "used=${ARR[5]}MB;;${total}; percent=${ARR[6]}%;$WARN;$CRIT; inodes_perc=${ARR[10]}%;$WARN;$CRIT;"

exit $status
