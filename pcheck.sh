#!/bin/bash
#

MFILE="/home/fhadmin/migrate.txt"

echo "Updating VMware tools."
/usr/bin/vmware-config-tools.pl -d

echo "--- KERNEL INFO" >$MFILE
uname -ra >>$MFILE
echo  --- KERNEL INFO ENDS$'\n\n' >>$MFILE

echo "--- DISK INFO" >>$MFILE
df -kh >>$MFILE
echo --- DISK INFO ENDS$'\n\n' >>$MFILE

echo "--- IP INFO">>$MFILE
ip addr |grep "inet "|grep eth >> $MFILE
echo --- IP INFO ENDS$'\n\n' >>$MFILE

echo "--- PORT INFO" >>$MFILE
netstat -plant >>$MFILE
echo --- PORT INFO ENDS$'\n\n' >>$MFILE

echo "--- OUTBOUND CONNECTIVITY" >>$MFILE
ping -c3 -W5 google.com >>$MFILE
echo --- OUTBOUND ENDS$'\n\n' >>$MFILE
echo "--- NOEXEC CHECK" >>$MFILE
cat /proc/mounts |grep -i noexec |grep tmp>>$MFILE
echo --- NOEXEC check ENDS$'\n\n' >>$MFILE
