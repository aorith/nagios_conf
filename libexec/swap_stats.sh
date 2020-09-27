#!/bin/bash
LC_ALL=C

[ $# -ne 3 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }
SERVER=$1
WARN=$2
CRIT=$3

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -S 1 3 |grep 'Average:'")"
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

# 10:48:09 AM kbswpfree kbswpused  %swpused  kbswpcad   %swpcad
# Average:      5213416         0      0.00         0      0.00
#  0             1           2           3        4          5

kbswpfree=${ARR[1]}
kbswpused=${ARR[2]}
swpused_perc=${ARR[3]}
kbswpcad=${ARR[4]}
swpcad_perc=${ARR[5]}  ## "cached" swap

text="Swpused:${kbswpused}KB/${swpused_perc}% - SwpCached:${kbswpcad}KB/${swpcad_perc}%"
perfdata="kbswpfree=${kbswpfree}KB;;;0; kbswpused=${kbswpused}KB;;;0; kbswpcad=${kbswpcad}KB;;;0; swpused_perc=${swpused_perc}%;$WARN;$CRIT;0; swpcad_perc=${swpcad_perc}%;$WARN;$CRIT;0;"

# testing if $1 > $2
_decimal_compare() {
    [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]
}

if _decimal_compare $swpused_perc $CRIT || _decimal_compare $swpcad_perc $CRIT; then 
    status=2
    text="CRITICAL: ${text}"
elif _decimal_compare $swpused_perc $WARN || _decimal_compare $swpcad_perc $WARN; then 
    status=1
    text="WARNING: ${text}"
fi

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
