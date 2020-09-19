#!/bin/bash
set -e

TEXT="$(echo "$*" |sed 's/\n/%0A/g')"
TOKEN="$(sed -n 1p ${HOME}/secret/alarms_aorithbot.txt)"
CHATID="$(sed -n 2p ${HOME}/secret/alarms_aorithbot.txt)"
TIME="20"
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"

# send message
curl -s --max-time $TIME -d "chat_id=${CHATID}&disable_web_page_preview=1&text=${TEXT}" "${URL}" >/dev/null

# receive messages
#URL_UPDATES="https://api.telegram.org/bot$TOKEN/getUpdates"
#curl -s --max-time $TIME $URL_UPDATES
