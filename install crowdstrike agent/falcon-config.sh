#!/bin/sh

# Check which OS version
#
if [ -f /etc/os-release ];then
OSN=`echo $(. /etc/os-release && echo $NAME) 2> /dev/null`
OSV=`echo $(. /etc/os-release && echo $VERSION_ID) | cut -d "." -f1`
OSNR=`echo $OSN | grep Red | wc -l`
OSNU=`echo $OSN | grep Ubuntu | wc -l`
elif [ -f /etc/redhat-release];then
OSV=`cat /etc/redhat-release | awk '{print $7}' | cut -d "." -f1`
fi

# Config  it
#
if [ -f /opt/CrowdStrike/falconctl ]; then
  /opt/CrowdStrike/falconctl -s --cid=<SOME NUMBERS>
  sleep 5
  echo "Check for CID, should be <SAME NUMBERS>"
  /opt/CrowdStrike/falconctl -g --cid
  echo
  echo "Check for AID to check console registration, this will take 30 seconds."
  sleep 30
  /opt/CrowdStrike/falconctl -g --aid
  echo
else
  echo "Falcon install not found."
  exit 1
fi

#
# Start it
#
if [ $OSV -lt 7 ]; then
   /sbin/service falcon-sensor start
else
   /usr/bin/systemctl start falcon-sensor
   echo "Check to ensure process is enabled"
   /usr/bin/systemctl is-enabled falcon-sensor
   echo
   echo "Check to ensure process is active/running"
   /usr/bin/systemctl is-active falcon-sensor
fi
echo -e "\nCrowdStrike agent version installed is:-"
if [ $OSNU -eq 1 ];then
   dpkg --list | grep 'falcon-sensor'
elif [ $OSNR -eq 1 ];then
   rpm -qa | grep 'falcon-sensor'
else
   echo "ERROR: Invalid OS"
fi
