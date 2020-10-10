#!/bin/bash

[ $# -ne 1 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1

output="$(ssh "aorith@${SERVER}" "ping -c3 -n -q 8.8.8.8")"
ret=$?
if [ $ret -eq 2 ]; then
    ssh "aorith@${SERVER}" "sudo chmod u+s /bin/ping"
    output="$(ssh "aorith@${SERVER}" "ping -c3 -n -q 8.8.8.8")"
    ret=$?
fi

[[ $req -ne 0 ]] && exit $ret


# --- 8.8.8.8 ping statistics ---
# 3 packets transmitted, 3 received, 0% packet loss, time 5ms
# rtt min/avg/max/mdev = 3.882/3.984/4.135/0.130 ms

packet_loss="$(echo "$output" |grep "packet loss" |awk '{ print $6 }')"
rta="$(echo "$output" |grep "rtt min" |awk -F'/' '{ print $5 }')"

re='[0-9\.]+'
if [[ ! ${rta} =~ $re ]]; then
    if echo "$output"|grep -q '100%'; then rta=-1 else
        { echo "Error reading ping output."; exit 3; }
    fi
fi

text="rta: ${rta}ms - packet_loss ${packet_loss}"
perfdata="rta=${rta}ms;15.000;20.000;0; packet_loss=${packet_loss};1.0;51.0;0;100"

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
