#!/bin/bash
#

echo "Updating VMware tools."
/usr/bin/vmware-config-tools.pl -d

echo "Saving Disk config to /home/fhadmin/disks.txt"
df -kh >/home/fhadmin/disks.txt

echo "Saving IP Addresses to /home/fhadmin/ips.txt"
ip addr |grep inet |grep eth |awk '{print $2}' >/home/fhadmin/ips.txt

