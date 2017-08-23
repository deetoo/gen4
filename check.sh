#!/bin/bash
#

# file to store all pre-migration values in.
MFILE="/home/fhadmin/migrate.txt"



# simple help screen explaining syntax.
DoHelp ()
	{
		echo "Syntax Error!";
		echo "$0 --pre  (this will execute all pre-migration checks.)";
		echo "$0 --post (this will execute all post-migration checks.)";
		exit 0;
	}

# monster function that runs all pre-migration checks.
PreMigration ()
	{
		echo "Starting pre-migration checks.";

		# 	
		# verify if /tmp is NOEXEC
		#
		if [ -x /tmp ]
	then
		echo "/tmp is executable.";
	else
		echo "/tmp is NOEXEC!";
		echo "Migration scripts will NOT execute unless this is fixed.";
		echo "Press a key to continue..";
		read PAUSE
fi

		#
		# verify that VMware Tools ISO is available
		# to mount, then copy and extract the archive.
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
		# check for Linux Distro, and create armor-vmware-tools init script.
		#

		# check for CentOS/RHEL

		if [ -f /etc/redhat-release ]
		then
			echo "This is a RHEL/CentOS box."
			echo "Installing ca-certificates and yum-plugin-security.."
			
			yum install -y yum-plugin-security ca-certificates
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

		# check for Ubuntu

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

		# update repos for all Distro types.
find /etc/{apt,yum,yum.repos.d} -type f -not -iname "*.bak*" -print -exec sed -i.bak.$RANDOM -e "s/[A-Za-z][A-Za-z][A-Za-z]01-pkg01\.firehost\.net/a.svc.armor.com/g" {} \;

		# save lots of data.

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

date >> $MFILE

echo "Pre-Migration tasks completed!"
exit 0;
}

# monster function that checks server status after migration.
PostMigration ()
	{
		echo "Starting post-migration checks.";
		exit 0;
	}


TEST=0
# verify root is executing the script.
if [ $TEST == 1 ]
 then
if [ $UID -ne "0" ]
	then
		echo "You must be the root user to execute this script.";
		exit 0;
	fi
fi

if [ $# -eq 0 ]
	then
		DoHelp
		exit 0
	fi

# parse the argument and do valid things for valid arguments.
while test $# -gt 0
	do
		case "$1" in
			--pre) echo "pre-migration run";
			PreMigration
			;;
			--post) echo "post-migration run";
			PostMigration
			;;
			*) DoHelp
			;;
		esac
		shift
	done

exit 0
