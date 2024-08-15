#!/bin/bash

TMPFL="/var/tmp/appvrsop"; echo -e "`hostname -s` =>" > $TMPFL
app1=`ps -u apache u | grep -i http | grep -v grep | awk '{print $11}' | sort -u`
app2=`ps -u tomcat u | grep -i catalina | grep -v grep | awk '{print $12}' | awk -F= '{print $2}'| sort -u`
app3=`ps -ef | grep -i http | grep -v grep | wc -l`
app4=`ps -ef | grep -i catalina | grep -v grep | wc -l`
app5=`ps -ef | grep -i jboss | grep -v grep | wc -l`
app6=`ps -ef | grep -i nginx | grep -v grep | wc -l`

if [ -n "$app1" ]; then
	echo -e "Below Apache running with 'svc-kzd-apache' user" >> $TMPFL
	for i in `echo $app1`
	do
		echo -e "Apache = $i" >> $TMPFL
	done
	echo "" >> $TMPFL
fi

if [ -n "$app2" ]; then
	echo -e "Below Tomcat running with 'svc-kzd-tomcat' user" >> $TMPFL
	for i in `echo $app2`
	do
		echo -e "Tomcat = $i" >> $TMPFL
	done
	echo "" >> $TMPFL
fi

if [ "$app3" -ge "1" -a -z "$app1" ]; then
	ps axo euser:20,cmd | grep -i http | grep -v grep | awk '{print $1}' | sort | uniq > /tmp/tempfl
        USR1=""
        for i in `cat /tmp/tempfl`; do
                USR2=`echo $(echo $i), $(echo $USR1)`;USR1="$USR2"
        done
        USR=`echo $USR1 | sed -n 's/,*\r*$//p'`
        echo -e "Another Apache running with '$USR' user/s\n" >> $TMPFL
fi

if [ "$app4" -ge "1" -a -z "$app2" ]; then
	ps axo euser:20,cmd | grep -i catalina | grep -v grep | awk '{print $1}' | sort | uniq > /tmp/tempfl
        USR1=""
        for i in `cat /tmp/tempfl`; do
                USR2=`echo $(echo $i), $(echo $USR1)`;USR1="$USR2"
        done
        USR=`echo $USR1 | sed -n 's/,*\r*$//p'`
        echo -e "Another Tomcat running with '$USR' user/s\n" >> $TMPFL
fi

if [ "$app5" -ge "1" ]; then
        ps axo euser:20,cmd | grep -i jboss | grep -v grep | awk '{print $1}' | sort -u > /tmp/tempfl
        USR1=""
        for i in `cat /tmp/tempfl`; do
                USR2=`echo $(echo $i), $(echo $USR1)`;USR1="$USR2"
        done
        USR=`echo $USR1 | sed -n 's/,*\r*$//p'`
        echo -e "Jboss running with '$USR' user/s\n" >> $TMPFL
fi

if [ "$app6" -ge "1" ]; then
        ps axo euser:20,cmd | grep -i nginx | grep -v grep | awk '{print $1}' | sort -u > /tmp/tempfl
        USR1=""
        for i in `cat /tmp/tempfl`; do
                USR2=`echo $(echo $i), $(echo $USR1)`;USR1="$USR2"
        done
        USR=`echo $USR1 | sed -n 's/,*\r*$//p'`
        echo -e "Nginx running with '$USR' user/s\n" >> $TMPFL
fi

db=`ps -ef | grep -i pmon | grep -v grep | wc -l`

if [ -z "$app1" -a -z "$app2" -a "$app3" -eq "0" -a "$app4" -eq "0" -a "$app5" -eq "0" -a "$app6" -eq "0" ]; then
	rm $TMPFL
fi

if [ "$db" -gt "0" ]; then
	rm $TMPFL
fi
