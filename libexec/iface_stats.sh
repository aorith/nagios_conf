#!/bin/bash
LC_ALL=C

[ $# -ne 2 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
IFACE=$2

output="$(ssh "aorith@${SERVER}" "LC_ALL=C sar -n DEV --iface=$IFACE 1 3 |grep 'Average:' |grep -v '%ifutil'")"
[[ -z "$output" ]] && { echo "No data retrieved"; exit 3; }

## hostname;interval;timestamp;IFACE;rxpck/s;txpck/s;rxkB/s;txkB/s;rxcmp/s;txcmp/s;rxmcst/s;%ifutil
#  0        1        2         3     4       5       6      7      8       9       10       11
#pve;120;2020-09-14 08:28:01;enp6s0f0;38.71;20.18;36.08;2.08;0.00;0.00;0.31;0.03

# Average:        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
# Average:         eth0      5.33      5.33      0.27      0.78      0.00      0.00      0.00      0.00
#  0               1          2         3         4        5          6        7         8         9

status=0
count=0
ARR=()
for field in $output;
do
    ARR[$count]="$field"
    count=$(( count + 1 ))
done

re='[0-9\.]+'
if [[ ! ${ARR[2]} =~ $re ]]; then
    echo "Error reading sadf(sar) output."
    exit 3
fi

text="$IFACE rxKB/s:${ARR[4]} txKB/s:${ARR[5]} Usage:${ARR[9]}"
perfdata="rxKBs_s=${ARR[4]}KB;;;0; txKBs_s=${ARR[5]}KB;;;0; Usage_perc=${ARR[9]}%;;;0;100"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
