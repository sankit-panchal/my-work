#!/bin/bash
#set -x
PREOUT="/var/tmp/preout";mkdir $PREOUT 2>/dev/null
POSTOUT="/var/tmp/postout";mkdir $POSTOUT 2>/dev/null
HN=`hostname -s | tr [:upper:] [:lower:] | cut -c1-2`
HNSC=`hostname -s | tr [:upper:] [:lower:] | cut -c1-6`
DT=`date '+%m-%d-%Y %T'`
if [ -f /etc/os-release ];then
        OSN=`echo $(. /etc/os-release && echo $PRETTY_NAME) 2> /dev/null`
        OSV=`echo $(. /etc/os-release && echo $VERSION_ID) | cut -d "." -f1 2> /dev/null`
else
        OSN=`cat /etc/redhat-release`
        OSV=`cat /etc/redhat-release | awk '{print $7}' | cut -d "." -f1`
fi

OSNH=`echo $OSN | awk '{print $1}'`

REPO7="/mnt/zts-rhel-7/zts-rhel7.repo"
REPO8="/mnt/kickstart/zoetis-web-rhel8.repo"
REPOU="/mnt/scripts/zoetis.list"

pre_boot (){
        if [ "$#" -ne 1 ]; then
                printf "Script usage is $0<space><change no.>"
                exit 1
        else
                # echo ""
                timeout 10 df -h > /dev/null
                ret=$(echo $?)
                if [ $ret -ge "1" ]; then
                        printf "\n========== $1 - $DT ==========\n" | tee -a $PREOUT/dfout $PREOUT/ipout $PREOUT/beforeupgrade > /dev/null
                        df -lhT | egrep -v "tmpfs|squashfs" >> $PREOUT/dfout
                        df -lhT | egrep -v "Type|tmpfs|squashfs" | awk '{print $NF}' | grep -v Mounted | sort | uniq > $PREOUT/dfout1
                        mount | egrep -i 'nfs|cifs' > $PREOUT/nfsout
                        mount | egrep -i 'type nfs|type cifs' | awk '{for(i=1;i<=NF;i++)if($i~/type/)print $(i-1)}' >> $PREOUT/dfout1
                        sort -u $PREOUT/dfout1 -o $PREOUT/dfout1
                else
                        printf "\n========== $1 - $DT ==========\n" | tee -a $PREOUT/dfout $PREOUT/ipout $PREOUT/beforeupgrade > /dev/null
                        df -hT | egrep -v "tmpfs|squashfs" >> $PREOUT/dfout
                        df -hT | egrep -v "Type|tmpfs|squashfs" | awk '{print $NF}' | grep -v Mounted | sort | uniq > $PREOUT/dfout1
                fi
                ip a >> $PREOUT/ipout
                ip a | grep inet | awk '{print $2}' | sort | uniq > $PREOUT/ipout1
                echo ""
                #/opt/zoetis-serverbuild/zrpw.sh shared 1> /dev/null
                ps axo user:20,pid,ppid,pcpu,start,time,tty,cmd > $PREOUT/psdetails
		lsmem | grep "Total online memory:" | awk -F: '{print $2}' | tr -d ' ' > $PREOUT/memdetail
		lscpu | grep "^CPU(s):" | awk -F: '{print $2}' | tr -d ' ' > $PREOUT/cpudetail
                if [ "$OSNH" = "Red" ]; then
                        mkdir /etc/yum.repos.d/bkp-repos
                        for i in `ls /etc/yum.repos.d/*.repo | egrep -v 'zts|zoetis-web'`;do mv -v $i /etc/yum.repos.d/bkp-repos/;done
                        echo ""
                        if [ "$HN" != "az" ]; then
    				if [ "$HNSC" = "kzdlsc" ]; then
					REPO7="/sc/kzd/depot/repos/zoetis-sc-rhel7.repo"
    				fi
				case $OSV in
					7)
						cp -v $REPO7 /etc/yum.repos.d/
						;;
					8)
						cp -v $REPO8 /etc/yum.repos.d/
						;;
				esac
			elif [ "$HN" = "az" ]; then
    				rm /etc/yum/vars/releasever
    				yum --disablerepo='*' remove rhui-azure-rhel$OSV* -y
    				yum --config=/tmp/rhui-microsoft-azure-rhel$OSV.config install rhui-azure-rhel$OSV -y
			fi
                        yum clean all
                        yum repolist
 		elif [ "$OSNH" = "Ubuntu" ]; then
			mkdir /etc/apt/bkp-sources
			cnt=`cat /etc/apt/sources.list | egrep -v "^$|^#" | grep "kzdl1000" | wc -l`
			cp -v /etc/apt/sources.list /etc/apt/bkp-sources/
                        #sed -i "s/^deb/#deb/" /etc/apt/sources.list
                        cd /etc/apt/sources.list.d/
                        for i in `ls /etc/apt/sources.list.d/*.list`;do mv -v $i /etc/apt/bkp-sources/;done
			if [ "$cnt" -lt "4" ]; then
				if [ "$HN" = "az" ]; then
					REPOU="/tmp/zoetis.list"
				fi
			cat $REPOU >> /etc/apt/sources.list
			fi
                       # cp -v $REPOU /etc/apt/sources.list.d/
		        if [ "$HN" = "az" ]; then
				#FLNM="/etc/ssl/certs/kzdl1000-selfsigned.pem"
				#if [ ! -L "$FLNM" ]; then
				update-ca-certificates
			fi
			apt-get clean all
                        apt-get update
                fi
                echo ""
                printf "Before Reboot :-\n" | tee -a $PREOUT/beforeupgrade | tee /var/tmp/beforeupgrade
                printf "Hostname :- `hostname -s`\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
                printf "OS Release :- $OSN\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
                printf "Kernel Version :- `uname -r`\n\n" | tee -a $PREOUT/beforeupgrade /var/tmp/beforeupgrade
                touch /var/tmp/rebooted
        fi
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

sdiff_mem (){
	memdif=`sdiff -s $POSTOUT/memdetail $PREOUT/memdetail`
	if [ -n "$memdif" ]; then
		echo "There is change in Memory."
		echo "Old Memory : `cat $PREOUT/memdetail`"
		echo "New Memory : `cat $POSTOUT/memdetail`"
		echo ""
	fi
}

sdiff_cpu (){
	cpudif=`sdiff -s $POSTOUT/cpudetail $PREOUT/cpudetail`
	if [ -n "$cpudif" ]; then
		echo "There is change in CPU."
		echo "Old CPU : `cat $PREOUT/cpudetail` cores"
		echo "New Memory : `cat $POSTOUT/cpudetail` cores"
		echo ""
	fi
}


if [ -f /var/tmp/rebooted ];then
        UPT=`uptime | grep day | wc -l`
        if [ $UPT -ge 1 ];then
                echo "System is not rebooted yet."
                exit 1
        fi
        echo ""
	if [ "$HN" != "az" ]; then
		/mnt/kickstart/zrpw.sh secure 1> /dev/null
		cp /mnt/kickstart/sudoers-0000-definitions /etc/sudoers.d/0000-definitions
	fi
        printf "\n========== $DT ==========\n" | tee -a $POSTOUT/dfout $POSTOUT/ipout $POSTOUT/afterupgrade > /dev/null
        df -hT | egrep -v "tmpfs|squashfs" >> $POSTOUT/dfout
        df -hT | egrep -v "Type|tmpfs|squashfs" | awk '{print $NF}' | grep -v Mounted | sort | uniq > $POSTOUT/dfout2
        sdiff_df | tee /var/tmp/dfcheck
        echo ""
        ip a >> $POSTOUT/ipout
        ip a | grep inet | awk '{print $2}' | sort | uniq > $POSTOUT/ipout2
        sdiff_ip | tee /var/tmp/ipcheck
        echo ""
	lsmem | grep "Total online memory:" | awk -F: '{print $2}' | tr -d ' ' > $POSTOUT/memdetail
	sdiff_mem | tee /var/tmp/memcheck
	lscpu | grep "^CPU(s):" | awk -F: '{print $2}' | tr -d ' ' > $POSTOUT/cpudetail
	sdiff_cpu | tee /var/tmp/cpucheck
        if [ "$OSNH" = "Red" ]; then
                if [ $OSV -le 7 ]; then
                        package-cleanup -y --oldkernels 2 2>&1 > /dev/null
                fi
                mv /etc/yum.repos.d/bkp-repos/* /etc/yum.repos.d/ 2>/dev/null
                rmdir /etc/yum.repos.d/bkp-repos
		if [ "$HN" = "az" ]; then
			echo $(. /etc/os-release && echo $VERSION_ID) > /etc/yum/vars/releasever
		fi
        elif [ "$OSNH" = "Ubuntu" ]; then
                mv -f /etc/apt/bkp-sources/sources.list /etc/apt/
                mv /etc/apt/bkp-sources/* /etc/apt/sources.list.d/ 2>/dev/null
                rmdir /etc/apt/bkp-sources
        fi
	for i in `realm list | grep permitted-groups | awk -F: '{print $2}' | tr ', ' '\n'`;do echo "getent group $i";getent group $i;echo "";done 1> /dev/null
        rm -f /var/tmp/rebooted
        # /opt/zoetis-serverbuild/zrpw.sh secure 1> /dev/null
        cat /var/tmp/beforeupgrade
        printf "After Reboot :-\n" | tee -a $POSTOUT/afterupgrade
        printf "Hostname :- `hostname -s`\n" | tee -a $POSTOUT/afterupgrade
        printf "OS Release :- $OSN\n" | tee -a $POSTOUT/afterupgrade
        printf "Kernel Version :- `uname -r`\n" | tee -a $POSTOUT/afterupgrade
else
        pre_boot $1
fi
