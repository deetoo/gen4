#!/bin/bash
#

mount /dev/sr0 /media

if [ -f /media/VMwareTools-10.1.7-5541682.tar.gz ]
	then
		echo "VMware Tools is being copied to /root"
		cp /media/VMware* /root
		cd /root
		echo "Extracting VMware Tools 10.1"
		tar zxf VMwareTools-10.1.7-5541682.tar.gz
		echo "Uninstalling legacy VMware Tools."
		vmware-uninstall-tools.pl
		echo "Installing VMware Tools 10.1"
		cd vmware-tools-distrib
		./vmware-install.pl

	else
		echo "VMware Tools not found in /media - exiting!"
		exit 0
	fi

MFILE="/home/fhadmin/migrate.txt"


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
