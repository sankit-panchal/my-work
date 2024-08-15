#!/bin/bash
#set -x
touch /var/tmp/timestatus
CHKNTP=`which ntpq 2> /dev/null`
NTP=`$CHKNTP -np 2> /dev/null`
NTPS=`echo $?`
CHKCHRNY=`which chronyc 2> /dev/null`
CHRNY=`$CHKCHRNY sources 2> /dev/null`
CHRNYS=`echo $?`
if [ $NTPS -eq "0" ]; then
	echo "NTP is running." > /var/tmp/timestatus
elif [ $CHRNYS -eq "0" ]; then
	echo "Chrony is running." > /var/tmp/timestatus
else
	echo "No time sync running." > /var/tmp/timestatus
fi
cat /var/tmp/timestatus
