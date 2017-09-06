#!/bin/bash
# Ping all ip address

for ip in 172.22.49.{1..254}; do
  # del old arp record
  sudo arp -d $ip > /dev/null 2>&1
  # get new arp info with ping
  ping -c 5 $ip > /dev/null 2>&1 &
done

# wait finish
wait

# output ARP table
arp -n | grep -v incomplete

