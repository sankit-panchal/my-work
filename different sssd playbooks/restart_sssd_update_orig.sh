#!/bin/bash
#  Created by: Sankit Panchal
#  Date : 04/20/2023

dt=`date +%Y%m%d%H%M%S`

cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf-$dt
flsts="UNCHANGED"
line1=`grep ^entry_cache_timeout /etc/sssd/sssd.conf | wc -l`
line2=`grep ^ad_site /etc/sssd/sssd.conf | wc -l`
if [ $line1 -ge "1" ];then
	sed -i '/^entry_cache_timeout/s/^/#/' /etc/sssd/sssd.conf
	flsts="CHANGED"
fi
if [ $line2 -lt "1" ];then
	sed -i '/^ad_domain/a ad_site = kzd' /etc/sssd/sssd.conf
	flsts="CHANGED"
fi

cp /etc/nscd.conf /etc/nscd.conf-$dt
for i in passwd group;do sed -i -e "s/enable-cache\t\t$i\t\tyes/enable-cache\t\t$i\t\tno/" /etc/nscd.conf;done
for i in services netgroup;do sed -i -e "s/enable-cache\t\t$i\tyes/enable-cache\t\t$i\tno/" /etc/nscd.conf;done
systemctl restart nscd

if [ $flsts == "CHANGED" ];then
systemctl stop sssd;rm -f /var/lib/sss/{db,mc}/*;systemctl start sssd
fi
sleep 5
for i in `realm list | grep permitted-groups | awk -F: '{print $2}' | tr ', ' '\n'`;do echo "getent group $i";getent group $i;echo "";done 1>/dev/null
