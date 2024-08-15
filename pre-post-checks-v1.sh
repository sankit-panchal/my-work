#!/bin/bash
#set -x
PREOUT="/var/tmp/prereboot";mkdir $PREOUT 2>/dev/null
POSTOUT="/var/tmp/postreboot";mkdir $POSTOUT 2>/dev/null
if [ -f /etc/os-release ];then
OSN=`echo $(. /etc/os-release && echo $NAME) 2> /dev/null`
OSV=`echo $(. /etc/os-release && echo $VERSION_ID) | cut -d "." -f1 2> /dev/null`
fi
if [ -f /etc/redhat-release ];then
OSN=`cat /etc/redhat-release`
OSV=`cat /etc/redhat-release | awk '{print $7}' | cut -d "." -f1`
fi

pre_boot (){
timeout 10 df -h > /dev/null
ret=$(echo $?)
if [ $ret -ge "1" ]; then
echo -e "\n========== $1 - $DT ==========\n" | tee -a $PREOUT/dfout $PREOUT/ipout $PREOUT/beforeupgrade > /dev/null
df -lhT | egrep -v "tmpfs|squashfs" >> $PREOUT/dfout
df -lhT | egrep -v "tmpfs|squashfs" | awk '{print $7}' | grep -v Mounted | sort | uniq > $PREOUT/dfout1
mount | egrep -i 'nfs|cifs' > $PREOUT/nfsout
mount | egrep -i 'type nfs|type cifs' | awk '{print $3}' >> $PREOUT/dfout1
sort -u $PREOUT/dfout1 -o $PREOUT/dfout1
else
echo -e "\n========== $1 - $DT ==========\n" | tee -a $PREOUT/dfout $PREOUT/ipout $PREOUT/beforeupgrade > /dev/null
df -hT | egrep -v "tmpfs|squashfs" >> $PREOUT/dfout
df -hT | egrep -v "tmpfs|squashfs" | awk '{print $7}' | grep -v Mounted | sort | uniq > $PREOUT/dfout1
fi
ip a >> $PREOUT/ipout
ip a | grep inet | awk '{print $2}' | sort | uniq > $PREOUT/ipout1
echo ""
#/opt/zoetis-serverbuild/zrpw.sh shared 1> /dev/null
ps axo user:20,pid,ppid,pcpu,start,time,tty,cmd > $PREOUT/psdetails
echo ""
printf "Before Reboot :-\n" | tee -a $PREOUT/beforeupgrade | tee /var/tmp/beforeupgrade
printf "Hostname :- `hostname -s`\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
printf "OS Release :- $OSN\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
printf "Kernel Version :- `uname -r`\n\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
touch /var/tmp/rebooted
}

sdiff_df (){
sdif=`sdiff -s $PREOUT/dfout1 $POSTOUT/dfout2 | grep "<" | awk '{print $1}'`
sdiff=`sdiff -s $PREOUT/dfout1 $POSTOUT/dfout2 | grep ">" | awk '{print $2}'`
if [ -n "$sdif" ]; then
 printf "Below mount point is missing\n"
 printf "$sdif\n"
fi
if [ -n "$sdiff" ]; then
 printf "Below mount point is newly added\n"
 printf "$sdiff\n"
fi
if [ -z "$sdif" -a -z "$sdiff" ]; then
  printf "Mount is good.\n"
fi
}

sdiff_ip (){
sdif=`sdiff -s $PREOUT/ipout1 $POSTOUT/ipout2 | grep "<" | awk '{print $1}'`
sdiff=`sdiff -s $PREOUT/ipout1 $POSTOUT/ipout2 | grep ">" | awk '{print $2}'`
if [ -n "$sdif" ]; then
 printf "Below IP is missing\n"
 printf "$sdif\n"
fi
if [ -n "$sdiff" ]; then
 printf "Below IP is newly added\n"
 printf "$sdiff\n"
fi
if [ -z "$sdif" -a -z "$sdiff" ]; then
  printf "IP Address is good.\n"
fi
}



if [ -f /var/tmp/rebooted ];then
UPT=`uptime | grep day | wc -l`
if [ $UPT -ge 1 ];then
 echo "System is not rebooted yet."
 exit 1
fi
 echo ""
 echo -e "\n========== $DT ==========\n" | tee -a $POSTOUT/dfout $POSTOUT/ipout $POSTOUT/afterupgrade > /dev/null
 df -hT | egrep -v "tmpfs|squashfs" >> $POSTOUT/dfout
 df -hT | egrep -v "tmpfs|squashfs" | awk '{print $7}' | grep -v Mounted | sort | uniq > $POSTOUT/dfout2
 sdiff_df | tee /var/tmp/dfcheck
 echo ""
 ip a >> $POSTOUT/ipout
 ip a | grep inet | awk '{print $2}' | sort | uniq > $POSTOUT/ipout2
 sdiff_ip | tee /var/tmp/ipcheck
 echo ""
 rm -f /var/tmp/rebooted
# /opt/zoetis-serverbuild/zrpw.sh secure 1> /dev/null
 cat /var/tmp/beforeupgrade
 printf "After Reboot :-\n" | tee -a $POSTOUT/afterupgrade
 printf "Hostname :- `hostname -s`\n" | tee -a $POSTOUT/afterupgrade
 printf "OS Release :- $OSN\n" | tee -a $POSTOUT/afterupgrade
 printf "Kernel Version :- `uname -r`\n" | tee -a $POSTOUT/afterupgrade
else
 pre_boot
fi
