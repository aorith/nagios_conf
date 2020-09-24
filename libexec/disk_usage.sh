#!/bin/bash
LC_ALL=C

[ $# -ne 3 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
WARN=$2
CRIT=$3

# testing if $1 > $2
_decimal_compare() {
    [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]
}

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -F MOUNT 1 2 |grep 'Summary:' |grep -v '%ufsused'")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

# Summary:     MBfsfree  MBfsused   %fsused  %ufsused     Ifree     Iused    %Iused MOUNTPOINT
# Summary:        21036     10961     34.26     36.35   1866325    230827     11.01 /var/log.hdd
#  0              1          2         3         4       5          6          7      8


status=0
old_IFS=$IFS
IFS=$'\n'
for line in $output; do
    count=0
    ARR=()
    IFS=$old_IFS
    for field in $line;
    do
        ARR[$count]="$field"
        count=$(( count + 1 ))
    done

    re='[0-9\.]+'
    if [[ ! ${ARR[4]} =~ $re ]]; then
        echo "Error reading sar output."
        exit 3
    fi

    disk_name="${ARR[8]/\//r_}"
    disk_name="${disk_name//\//_}"

    msg="OK:"
    if _decimal_compare ${ARR[7]} $WARN; then [[ $status -ne 2 ]] && status=1; msg="WARNING:"; fi
    if _decimal_compare ${ARR[7]} $CRIT; then status=2; msg="CRITICAL:"; fi
    if _decimal_compare ${ARR[4]} $WARN; then [[ $status -ne 2 ]] && status=1; msg="WARNING:"; fi
    if _decimal_compare ${ARR[4]} $CRIT; then status=2; msg="CRITICAL:"; fi

    total=$(echo "${ARR[1]} + ${ARR[2]}" |bc )

    text="${text}$msg ${ARR[8]} ${ARR[2]}MB/${total}MB(${ARR[4]}%) - Iused:${ARR[6]}(${ARR[7]}%)  "
    perfdata="${perfdata}${disk_name}_used=${ARR[2]}MB;;${total};0;${total} ${disk_name}_percent=${ARR[4]}%;$WARN;$CRIT;0;100 ${disk_name}_inodes_perc=${ARR[7]}%;$WARN;$CRIT;0;100 "
done

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status

