#!/bin/bash
#

MFILE="/home/fhadmin/migrate.txt"

echo "Updating VMware tools."
/usr/bin/vmware-config-tools.pl -d

echo "--- DISK INFO" >$MFILE
df -kh >>$MFILE
echo --- DISK INFO ENDS$'\n\n' >>$MFILE

echo "--- IP INFO">>$MFILE
ip addr |grep "inet "|grep eth >> $MFILE
echo --- IP INFO ENDS$'\n\n' >>$MFILE

echo "--- PORT INFO" >>$MFILE
nmap -P0 localhost >>$MFILE
echo --- PORT INFO ENDS$'\n\n' >>$MFILE

echo "--- NOEXEC CHECK" >>$MFILE
cat /proc/mounts |grep -i noexec |grep tmp>>$MFILE
echo --- NOEXEC check ENDS$'\n\n' >>$MFILE
