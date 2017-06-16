#!/bin/bash
#

MFILE="/home/fhadmin/migrate.txt"

echo "Updating VMware tools."
/usr/bin/vmware-config-tools.pl -d

echo "DISK INFO" >$MFILE
df -kh >>$MFILE

echo "IP INFO">>$MFILE
ip addr >> $MFILE

echo "PORT INFO" >>$MFILE
nmap -P0 localhost >>$MFILE

echo "END" >>$MFILE
