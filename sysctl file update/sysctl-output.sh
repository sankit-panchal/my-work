#!/bin/bash

for SETTING in \
net.core.rmem_max \
net.core.wmem_max \
net.core.wmem_default \
net.core.rmem_default \
net.core.optmem_max \
net.ipv4.tcp_rmem \
net.ipv4.tcp_wmem \
net.core.netdev_max_backlog \
net.core.netdev_budget \
net.core.somaxconn \
net.ipv4.tcp_max_syn_backlog \
net.ipv4.tcp_slow_start_after_idle \
net.ipv4.udp_wmem_min \
net.ipv4.udp_rmem_min
do
   sysctl $SETTING
done
