#!/bin/bash

[ $# -ne 3 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
WARN=$2
CRIT=$3

# testing if $1 > $2
_decimal_compare() {
    [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]
}

last_entry_date="$(ssh "aorith@${SERVER}" "sadf -dt -- -F MOUNT|cut -d';' -f3|tail -1")"
output="$(ssh "aorith@${SERVER}" "sadf -dt -- -F MOUNT|grep \"${last_entry_date}\"")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

## hostname;interval;timestamp          ;MOUNTPOINT;MBfsfree;MBfsused;%fsused;%ufsused;Ifree ;Iused;%Iused
# nagios   ;120     ;2020-09-14 08:28:01;/         ;5400    ;2600    ;32.50  ;37.82   ;459151;65137;12.42
#  0        1        2                   3          4        5        6       7        8      9     10

status=0
old_IFS=$IFS
IFS=$'\n'
for line in $output; do
    IFS=';'
    count=0
    ARR=()
    for field in $line;
    do
        ARR[$count]="$field"
        count=$(( count + 1 ))
    done
    IFS=$old_IFS

    re='[0-9]+'
    [[ ! ${ARR[4]} =~ $re ]] && { echo "Error reading sadf(sar) output."; exit 3; }

    disk_name="${ARR[3]/\//r_}"
    disk_name="${disk_name//\//_}"

    msg="OK:"
    if _decimal_compare ${ARR[10]} $WARN; then [[ $status -ne 2 ]] && status=1; msg="WARNING:"; fi
    if _decimal_compare ${ARR[10]} $CRIT; then status=2; msg="CRITICAL:"; fi
    if _decimal_compare ${ARR[6]} $WARN; then [[ $status -ne 2 ]] && status=1; msg="WARNING:"; fi
    if _decimal_compare ${ARR[6]} $CRIT; then status=2; msg="CRITICAL:"; fi

    total=$(echo "${ARR[4]} + ${ARR[5]}" |bc )

    text="${text}$msg ${ARR[3]} ${ARR[5]}MB/${total}MB(${ARR[6]}%) - Iused:${ARR[9]}(${ARR[10]}%)  "
    perfdata="${perfdata}${disk_name}_used=${ARR[5]}MB;;${total};0;${total} ${disk_name}_percent=${ARR[6]}%;$WARN;$CRIT;0;100 ${disk_name}_inodes_perc=${ARR[10]}%;$WARN;$CRIT;0;100 "
done

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status

