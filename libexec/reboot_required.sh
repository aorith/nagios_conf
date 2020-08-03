#!/bin/sh

[ -z "$1" ] && exit 2

if /usr/bin/timeout 5 /usr/bin/ssh "aorith@${1}" "test -f /var/run/reboot-required"; then
    echo "Reinicio necesario"
    exit 1
fi

echo "No hace falta reiniciar"

