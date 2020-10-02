#!/bin/bash

status=0
SERVER=$1
REMOTES="gdrive-msp gdrive-aoasir gdrive-farfe dropbox-ao"

for remote in $REMOTES; do
    output="$(ssh "aorith@${SERVER}" "sudo -u syncthing /home/syncthing/githome/st-backup/rclone/rclone about ${remote}: --json")"
    total="$(jq '.total' <<< "$output")"
    used="$(jq '.used' <<< "$output")"
    free="$(jq '.free' <<< "$output")"
    text="${text}[$remote total:$total used:$used free:$free] "
    perfdata="${perfdata} ${remote}_total=${total}b;;;0; ${remote}_used=${used}b;;;0; ${remote}_free=${free}b;;;0; "
done

echo -n "$text"
echo -n "|"
echo "$perfdata"
exit $status
