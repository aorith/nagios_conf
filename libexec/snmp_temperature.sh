#!/bin/sh

TEMP="$(snmpwalk -v2c -c mono ${1} iso.3.6.1.4.1.2021.7890.1.4.1.2.11.116.101.109.112.101.114.97.116.117.114.101.1 |cut -d'"' -f2|tr -d '"')"
echo "$TEMP"
EXITCODE=$(snmpwalk -v2c -c mono ${1} iso.3.6.1.4.1.2021.7890.1.3.1.4.11.116.101.109.112.101.114.97.116.117.114.101|awk '{print $NF}')
exit $EXITCODE
