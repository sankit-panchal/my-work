#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <Attached Hard disk name> <Mount Point name>"
  exit 1
fi

disknm=$1
mntnm=$2
#disknm=`fdisk -l | grep ^Disk | egrep -iv "ident|loop|mapper|label|model" | grep "$disksz GiB" | awk '{print $2}' | tr -d :`
vgnm=`df -hT $mntnm | tail -1 | awk '{print $1}' | awk -F/ '{print $4}' | awk -F- '{print $1}'`
lvnm=`df -hT $mntnm | tail -1 | awk '{print $1}' | awk -F/ '{print $4}' | awk -F- '{print $2}'`
lscnt=`ls $disknm* | wc -l`
if [ $lscnt -gt "1" ]; then
	echo -e "Partition is already created for - $disknm."
	exit 2
fi

if [ -z $disknm ]; then
	echo -e "$disksz - Hard Disk is absent."
elif [ -z $lvnm ]; then
	echo -e "Mount point $mntnm is not created in LV OR mount point $mntnm is absent."
else
	echo -e "n\np\n1\n\n\nt\n8e\nw" | fdisk $disknm 1> /dev/null
	partdisknm=`fdisk -l $disknm | grep "Linux LVM" | awk '{print $1}'`
	vgextend $vgnm $partdisknm 1> /dev/null
	lvextend -l +100%FREE $vgnm/$lvnm $partdisknm 1> /dev/null
	xfs_growfs /dev/$vgnm/$lvnm 1> /dev/null
	echo -e "Mount point $mntnm extended successfully."
	df -hT $mntnm | tail -1
fi
