#!/bin/bash
#
clear
if [ -d /.armor/backup ]
	then
		echo "Pre-migration scripts executed.";
		else
		echo "Could not find /.armor/backup";
		echo "Pre-migration script issues.";
		echo "Exiting!";
		exit 0
	fi

echo "Mounting VMware Tools ISO.."

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
		./vmware-install.pl -d

		umount /media

	else
		echo "VMware Tools not found in /media - exiting!"
		exit 0
	fi
#
# check for Distro
#
	if [ -f /etc/redhat-release ]
		then
			echo "This is a RHEL/CentOS box."
			yum install yum-plugin-security
			cat > /etc/init.d/armor-vmware-tools << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          armor-vmware-tools
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Armor VMware tools automatic update script
# Description:       Armor VMware tools automatic update script
### END INIT INFO
#
# Identifies new kernel versions, kicks off a reconfigure if a new version is detected
# Discover kernel versions in Guest OS
find /boot -type f -iname 'initramfs*' -print -exec bash -c "KERNEL=\$(echo {} | sed -e 's/^.*initramfs\-//' -e 's/\.img.*$//')
    test -f /boot/\$KERNEL.vmtools && echo Skipping \$KERNEL || (echo Building for \$KERNEL
    vmware-config-tools.pl -d -k \"\$KERNEL\" && touch /boot/\$KERNEL.vmtools)" \;
EOF
			chmod 755 /etc/init.d/armor-vmware-tools
			chkconfig armor-vmware-tools on
			service armor-vmware-tools
		fi

	if [ -f /etc/debian_version ]
		then
			echo "This is a Debian/Ubuntu box."
			cat > /etc/init.d/armor-vmware-tools << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          armor-vmware-tools
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Armor VMware tools automatic update script
# Description:       Armor VMware tools automatic update script
### END INIT INFO
#
# Identifies new kernel versions, kicks off a reconfigure if a new version is detected
# Discover kernel versions in Guest OS
find /boot -type f -iname 'initrd*' -print -exec bash -c "KERNEL=\$(echo {} | sed -e 's/^.*initrd\-//')
    test -f /boot/\$KERNEL.vmtools && echo Skipping \$KERNEL || (echo Building for \$KERNEL
    vmware-config-tools.pl -d -k \"\$KERNEL\" && touch /boot/\$KERNEL.vmtools)" \;
EOF
			chmod 755 /etc/init.d/armor-vmware-tools
			update-rc.d armor-vmware-tools defaults
			service armor-vmware-tools
		fi


	find /etc/{apt,yum,yum.repos.d} -type f -not -iname "*.bak*" -print -exec sed -i.bak.$RANDOM -e "s/[A-Za-z][A-Za-z][A-Za-z]01-pkg01\.firehost\.net/a.svc.armor.com/g" {} \;

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
