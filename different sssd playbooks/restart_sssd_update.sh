#!/bin/bash
#  Created by: Sankit Panchal
#  Date : 04/20/2023

for i in `realm list | grep permitted-groups | awk -F: '{print $2}' | tr ', ' '\n'`;do echo "getent group $i";getent group $i;echo "";done 1>/dev/null
