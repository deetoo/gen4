#!/bin/bash
#
# This is the magical 'do all the things' script.
# Brought to you by the letter 'D'.
#
#
# CHANGELOG
#
# 1.0a 
# - initial version of the script. mucho alpha
#
# 1.1a - 2 Sept 2017
# - added checks to detect Bomgar, and Trend Deep Security processes.
# - added fnction to update old ntp servers to gen4 and re-synch time after migration.
#
# 1.2a - 6 Sept 2017
# - added more DEBUG options
# added --report to generate before<>after report for internal ticket comment.
#
# 1.3a - 9 Sept 2017
# - added vmware tools pre/post migration version checking.
# - added --ver switch to check script version.
#
# 1.3b - 14 Sept 2017
# - removed CheckNTP, because we update the ntp servers in --post
# fixed broken if statement for removing open-vm-tools on Ubuntu
#
# 1.4a - 14 Sept 2017
# added DoUpdate checks running script version vs latest available in repo.
# option to directly download the latest script from the repo using --ver
#
# 1.5a - 27 Sept 2017
# added pre/post comparison of any iptables rules.
# migration oftentimes flips network interfaces which can break rules
# created in Gen3 that use NIC-specific rules.
# 
# keep track of versions.
VER="1.5a"

# 0 = false, 1 = true 
# if true, this will skip some steps.
DEBUG=1

# 0 = false, 1 = true
# whether or not to install vmware tools.
TOOLS=0

 
# file to store all pre-migration values in.
MFILE="/home/fhadmin/migrate.txt"



# simple help screen explaining syntax.
DoHelp ()
	{
		clear
		echo "Syntax Error!";
		echo "$0 --pre  (this will execute all pre-migration checks.)";
		echo "$0 --post (this will execute all post-migration checks.)";
		echo "$0 --ver (prints version of this script.)";
		exit 0;
	}



# monster function that runs all pre-migration checks.
PreMigration ()
	{
	
		clear
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
					#
					# add check here for Ubuntu, if found open-vm-tools package, remove it.
					if [ -f /etc/debian_version ]
					then
						apt-get remove -y open-vm-tools
					fi
					# end check
					# if open-vm-tools were installe,d the default would be NOT to
					# install on the line below. This caused issues.
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

iptables -L >/home/fhadmin/iptables.txt

echo "-- VMWARE TOOLS VERSION" >$MFILE
vmware-toolbox-cmd -v >>$MFILE
echo --- TOOLS VERSION ENDS$'\n\n' >>$MFILE

echo "--- KERNEL INFO" >>$MFILE
uname -r >> $MFILE
echo  --- KERNEL INFO ENDS$'\n\n' >>$MFILE

echo "--- DISK INFO" >>$MFILE
df -kh >> $MFILE
echo --- DISK INFO ENDS$'\n\n' >>$MFILE

echo "--- IP INFO">>$MFILE
ip addr |grep "inet "|grep eth >> $MFILE
echo --- IP INFO ENDS$'\n\n' >>$MFILE

echo "--- PORT INFO" >>$MFILE
netstat -plant >> $MFILE
echo --- PORT INFO ENDS$'\n\n' >>$MFILE

echo "--- OUTBOUND CONNECTIVITY" >>$MFILE
ping -c3 -W5 google.com >>$MFILE
echo --- OUTBOUND ENDS$'\n\n' >>$MFILE

echo `date` >> $MFILE

echo "Pre-Migration tasks completed!"
exit 0;
}

# CheckVersion - compares running version with the latest version in the GitHub repo.
#
CheckVersion ()
	{
	LATEST=`curl -s https://github.com/deetoo/gen4 |grep "Latest Version" -A2  |grep "<li>" |cut -d">" -f2 |awk '{print $1}'`
	if [ $VER != $LATEST ];
		 then
			echo You are running version $VER, $LATEST is available.$'\n';
			DoUpdate
			exit 0;
		else
			echo "You are running the latest version of this script: $LATEST";
			exit 0;
		fi
	}

DoUpdate ()
	{
		echo -n "Would you like to download the latest version of this script? [y/n]: ";	
		read DOWNLOAD
	
		if [ ${DOWNLOAD,,} == "y" ];
			then
				echo $'\n\n'Downloading..;
				wget https://raw.githubusercontent.com/deetoo/gen4/master/check.sh -O check.sh
		fi	
		exit 0;
	}

# Post migration functions.
# check if bomgar is running.
CheckBomgar ()
	{
		echo $'\n\n'Looking for Bomgar process:;
		ps aux |grep bomgar-pec
		echo $'\n\n'Check completed.;
	}

#check for pre and post migration kernel versions.
CheckKernel ()
	{
		echo $'\n\n'Pre-migration kernel:;
		grep x86_64 $MFILE	
		echo $'\n\n'Post-migration kernel:;
		uname -r
	}
# check for pre and post migration vmware tools versions.
CheckTools ()
	{
		echo $'\n\n'Pre-migration VMware tools:;
		grep build $MFILE
		echo $'\n\n'Post-migration VMware Tools:;
		vmware-toolbox-cmd -v
	}
# check for Trend Deep security.
CheckTrend ()
	{
		echo $'\n\n'Looking for Trend processes:;
		ps aux |grep ds_agent
		echo $'\n\n'Check completed.;
	}

# compare pre and post migration disk layout.
CheckDisks ()
	{
		echo $'\n\n'Pre-migration disk layout:;
		grep "/dev" $MFILE
		echo $'\n\n'Post-migration disk layout:;
		df -kh |grep "/dev"
	}

# compare pre and post network devices.
CheckNICs ()
	{
		echo $'\n\n'Pre-migration network addresses:;
		grep inet $MFILE
		echo $'\n\n'Post-migration network addresses:;
		ip addr |grep "inet "|grep eth
	}

CheckOutbound ()
	{
		echo $'\n\n'Pre-migration outbound connectivity:;
		grep packet $MFILE
	
		echo $'\n\n'Post-migration outbound connectivity:;
		ping -c3 -W5 google.com |grep packet
	}
# check for generic processes that were running before migration,
# then compare them to the generic processes after migration.
# this is an INCOMPLETE list of processes and will continue to grow.
CheckProcs ()
	{
		echo $'\n\n'Pre-migration generic processes:;
		grep -E 'apache|httpd|sshd|exim|mysqld|nginx|java' $MFILE |awk '{ print $7 }' |cut -d/ -f2 |sort -u 

		echo $'\n\n'Post-migration generic processes:;
		netstat -plant | grep -E 'apache|httpd|nginx|sshd|exim|mysqld|java' |awk '{print $7}' |cut -d/ -f2 |sort -u
	}

# update ntp servers. This has to be done in post-migration, 
# as the new ntp servers are not accessible in gen3.
# we replace the legacy servers, run ntpdate to update time,
# and then restart the service.
#
# this only works if the servers has one of our legacy NTP servers listed below.
FixNTP ()
	{
	echo $'\n\n'Updating NTP servers:;
	cp /etc/ntp.conf /tmp/ntp.conf.bak
	#
	# replace old with new gen4 ntp servers
	sed -i 's/DFW01-ts01.firehost.net/147.75.16.13/g' /etc/ntp.conf
	sed -i 's/DFW01-ts02.firehost.net/147.75.16.14/g' /etc/ntp.conf

	sed -i 's/PHX01-ts01.firehost.net/147.75.16.13/g' /etc/ntp.conf
	sed -i 's/PHX01-ts01.firehost.net/147.75.16.14/g' /etc/ntp.conf
	# update server time using new ntp server
	ntpdate -u 147.75.16.13
	# restart ntpd service
	service ntpd restart
	echo $'\n\n'NTP servers updated, synched, service restarted:;
	}


# check iptables rules before/afer migration.
DoIPtables ()
	{
		echo $'\n\n'Pre-migration iptables:;
		cat /home/fhadmin/iptables.txt
	        echo $'\n\n'Pre-migration outbound connectivity:;	
		iptables -L
	}
# monster function that checks server status after migration.
PostMigration ()
	{
		clear
		echo "---Post-Migration Report---";
		echo "Server: " `hostname`
		echo "The pre-migration script was created on:" `tail -2 $MFILE`;
		echo "The post-migration report was generated on:" `date`

		CheckKernel

		CheckTools

		CheckDisks

		CheckNICs

		CheckOutbound

		CheckProcs

		CheckBomgar

		CheckTrend

		DoIPtables

		FixNTP

		echo "--- END REPORT ---"; 
		
		exit 0;
	}


# verify root is executing the script.
if [ $DEBUG == 0 ]
 then
if [ $UID -ne "0" ]
	then
		echo "You must be the root user to execute this script.";
		exit 0;
	fi
fi

# show syntax if script is called without an argument.
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
			--ver) CheckVersion; 
			;;
			*) DoHelp
			;;
		esac
		shift
	done

exit 0
