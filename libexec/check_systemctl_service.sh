#!/bin/sh

[ $# -ne 2 ] && { echo "Bad invocation: \"$0 $*\""; exit 3; }

SERVER=$1
SERVICE=$2

status="$(timeout 10 ssh "aorith@${SERVER}" "systemctl status $SERVICE 2>/dev/null")"
ret=$?

echo "$status"|grep 'Active:'
exit $ret

