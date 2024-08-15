#!/bin/bash

mount | grep cifs | grep -v autofs | awk '{print $3}' | grep "/sc/cifs" > /var/tmp/cifsshares
for i in `cat /var/tmp/cifsshares`;do umount $i;cd $i;cd /sc/cifs;done
