#!/bin/bash
#

MFILE="/home/fhadmin/migrate.txt"

echo "Updating VMware tools."
/usr/bin/vmware-config-tools.pl -d

echo "--- DISK INFO" >$MFILE
df -kh >>$MFILE
echo "--- DISK INFO ENDS" >>$MFILE

echo "--- IP INFO">>$MFILE
ip addr >> $MFILE
echo "--- IP INFO ENDS" >>$MFILE

echo "--- PORT INFO" >>$MFILE
nmap -P0 localhost >>$MFILE
echo "--- PORT INFO ENDS" >>$MFILE

echo "--- NOEXEC CHECK" >>$MFILE
cat /proc/mounts |grep -i noexec >>$MFILE
echo "--- NOEXEC check ENDS" >>$MFILE
