#!/bin/ksh
################################################################################
#
# Documentation
# ==============================================================================
# This script is used to automatically installs IBM WebSphere Message Queue in
# AIX, Solaris and Linux (RHEL)
# ==============================================================================
#
# Version Control
# ==============================================================================
#  Ver 1.0.3 - Created by Franco Bontorin  
################################################################################


##########################
# VARIABLE DECLARATION   #
##########################

PLATFORM=$(uname)
ARCH=$(uname -p)
HOSTNAME=$(uname -n)
LOG_FILE=/tmp/UTS-MQ-Installation_$(date +'%d.%b.%Y-%I.%M%p').log


#############
# FUNCTIONS
#############

#
#PREPARE ENVIRONMENT
#
		
function printLog {

	# Send the input to the screen and to a log file
	
	printf "$@" 2>&1 | tee -a $LOG_FILE
	return 0
}

function abortProceed {
	
	printLog "\n--------------------------------------------------------------------------------\n"
	printLog "\n$(tput bold) PRESS < Y > TO PROCEED OR < A > TO ABORT:  $(tput sgr0)"
	read enterKey
	until [[ "$enterKey" = +([Y|y|A|a]) ]]
	do
		read enterKey?" Press < Y > to proceed or < A > to abort:  " 
	done
	if [ "$enterKey" == "A" ] || [ "$enterKey" == "a" ]
	then
		printLog "\n Process aborted by the user\n\n"
		printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n"
		exit 1					
	fi
	printLog "\n"

}
	
#
# GLOBAL
#

function uninstallMQ {
	
	printLog "\n==========================\n"
	printLog " WEBSPHERE MQ - UNINSTALL\n"
	printLog "==========================\n\n"
	
	printLog " Searching for active instances of MQ in the system -------------------- \033[01;32m[  OK  ]\033[00m\n\n"
	ps -ef |grep -i mq | grep -v grep | grep -v start | grep -v uninstall | grep -v .sh | grep -v sesudo | grep -v .log >> $LOG_FILE 2>&1
	ps -ef |grep -i mq | grep -v grep | grep -v start | grep -v uninstall | grep -v .sh | grep -v sesudo | grep -v .log
	[ $? -eq 0 ] && printLog " MQ is still active, stop these instances to proceed ------------------- \033[01;31m[ Failed ]\033[00m\n\n" && return 1
	
	
	case $PLATFORM in 
	
	(AIX)
		
		printLog " Identifying MQ Packages installed in the system ----------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		lslpp -al mqm* | grep -vE "^($|Path)" >> $LOG_FILE 2>&1; lslpp -al mqm* | grep -vE "^($|Path)"
		[ $? -ne 0 ] && printLog "\n IBM MQ is not installed on $HOSTNAME ---------------------------------- \033[01;32m[  OK  ]\033[00m\n\n" && return 1
		
		printLog "\n================================================================================\n"
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n"
		abortProceed
		
		printLog "================================================================================\n"
		printLog "\n Uninstalling MQ Packages, this may take several minutes to complete \n\n"
		/usr/sbin/installp -C mqm* >> $LOG_FILE 2>&1
		/usr/sbin/installp -u mqm* >> $LOG_FILE 2>&1
		[ $? -ne 0 ] && printLog " Errors happened during MQ Uninstall Process -------------------------- \033[01;31m[ Failed ]\033[00m\n\n" && return 1
		
	;;
 
	(Linux)
	
		printLog " Identifying MQ Packages installed in the system ----------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		rpm -qa |grep -i mqseries >> $LOG_FILE 2>&1
		rpm -qa |grep -i mqseries
		[ $? -ne 0 ] && printLog " IBM MQ is not installed on $HOSTNAME ---------------------------------- \033[01;32m[  OK  ]\033[00m\n\n" && return 1
				
		printLog "\n================================================================================\n"
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n"
		abortProceed
		
		printLog "================================================================================\n"
		printLog "\n Uninstalling MQ Packages, this may take several minutes to complete \n\n"
		packages="MQSeriesGSKit MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesServer MQSeriesTXClient MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesRuntime"
		for rpms in $packages
		do 
			for i in $(rpm -qa |grep -i $rpms | sort -ru)
			do 
				rpm -ev --test $i
				if [ $? -eq 0 ]
				then
					rpm -ev $i
				else
					printLog " Errors happened during MQ Uninstall Process -------------------------- \033[01;31m[ Failed ]\033[00m\n\n Please, consider to manually remove MQ packages\n\n " && return 1
				fi
			done
		done
						
	;;
	
	(SunOS)
	
		printLog " Identifying MQ Packages installed in the system ----------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		pkginfo | grep -w "mqm" | nawk '{print $2}' >> $LOG_FILE 2>&1; pkginfo | grep -w "mqm"
		[ $? -ne 0 ] && printLog " IBM MQ is not installed on $HOSTNAME ---------------------------------- \033[01;32m[  OK  ]\033[00m\n\n" && return 1

		printLog "\n================================================================================\n"
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n"
		abortProceed
		printLog "================================================================================\n"
		printLog " \n Uninstalling MQ Packages, this may take several minutes to complete \n\n"
		for package in $(/usr/bin/pkginfo | grep -w mqm | nawk '{print $2}' | sort -rn)
		do
			yes|pkgrm $package >> $LOG_FILE 2>&1
			[ $? -ne 0 ] && return 1
		done
	;;
	
	esac
	
	printLog " IBM MQ Uninstall Process finished ------------------------------------ \033[01;32m[  OK  ]\033[00m \n\n"

}
	

function preInstallMQ {

 # The mqconfig script analyzes your AIX, HP-UX, Linux or Solaris system to make
 # sure its kernel paramaters and other settings match the values recommended by
 # IBM in the WebSphere MQ documentation.  For each parameter, mqconfig displays
 # the current value, the current resource usage where possible, the recommended
 # setting from IBM, and a PASS/WARN/FAIL grade.
	
	printLog "\n============================\n"
	printLog " WEBSPHERE MQ - PRE SCRIPTS\n"
	printLog "============================\n\n"
	
	printLog " Searching for active instances of MQ in the system -------------------- \033[01;32m[  OK  ]\033[00m\n\n"
	ps -ef |grep -i mq | grep -v grep | grep -v start | grep -v uninstall | grep -v .sh | grep -v sesudo | grep -v .log >> $LOG_FILE 2>&1
	ps -ef |grep -i mq | grep -v grep | grep -v start | grep -v uninstall | grep -v .sh | grep -v sesudo | grep -v .log
	[ $? -eq 0 ] && printLog " MQ is still active, stop these instances to proceed ------------------- \033[01;31m[ Failed ] \033[00m \n\n" && return 1
	
	printLog " Verifying the existence of MQ User in the system ---------------------- "
	grep "^mqm:" /etc/passwd > /dev/null
	if [ $? -eq 0 ]
	then
		printLog "\033[01;32m[  OK  ]\033[00m"
	else
		printLog "\033[01;31m[ Failed ]\033[00m --> mqm user NOT created, please check with GIS and try again\n\n"
		return 1
	fi
	
	printLog "\n\n Checking the presence of dedicated filesystems for MQ ----------------- "
	df -k | grep "/var/mqm" > /dev/null || df -k | grep "/opt/mqm" || df -k | grep "/usr/mqm" > /dev/null
	if [ $? -eq 0 ]
	then
		printLog "\033[01;32m[  OK  ]\033[00m"
	else
		printLog "\033[01;31m[ Failed ]\033[00m --> MQ Filesystem NOT created, please create it and try again\n\n"
		return 1
	fi
	
	case $PLATFORM in 
	
	(AIX)
	
		printLog "\n\n Configuring Kernel Settings ------------------------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		CUR_MAXUPROC=$(lsattr -El sys0 -a maxuproc 2>/dev/null | awk '{print $2}')
		if [ "$CUR_MAXUPROC" -lt "1024" ]
		then
			chdev -l sys0 -a maxuproc='1024' >> $LOG_FILE 2>&1
		fi
		
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1
		if [ $? -ne 0 ] 
		then
			abortProceed
		fi
		export FREE_SPACE=$(df -k /var | tail -1 | awk '{print $3}')
	;;
	
	(Linux)
	
		printLog "\n\n Configuring Kernel Settings ------------------------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		
		cp /etc/sysctl.conf	/etc/sysctl.conf_$(date +'%d.%b.%Y-%I.%M%p')
		
		grep -q "kernel.msgmni" /etc/sysctl.conf > /dev/null 2>&1
		[ $? -ne 0 ] && echo "kernel.msgmni = 1024" >> /etc/sysctl.conf
		
		grep -q "kernel.shmmni" /etc/sysctl.conf > /dev/null 2>&1
		[ $? -ne 0 ] && echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
		
		grep -q "kernel.sem" /etc/sysctl.conf > /dev/null 2>&1
		[ $? -ne 0 ] && echo "kernel.sem = 500 256000 250 2014" >> /etc/sysctl.conf
		
		grep -q "fs.file-max" /etc/sysctl.conf > /dev/null 2>&1
		[ $? -ne 0 ] && echo "fs.file-max = 524288" >> /etc/sysctl.conf
		
		sysctl -p >> $LOG_FILE 2>&1
		
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1
		if [ $? -ne 0 ] 
		then
			abortProceed
		fi
		export FREE_SPACE=$(df -k /var | tail -1 | awk '{print $3}')
		
	;;
	
	(SunOS)
		
		printLog "\n\n Checking if MQ project is created ------------------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		grep group.mqm /etc/project > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			projadd -c "WebSphere MQ default settings" -K "process.max-file-descriptor=(basic,10000,deny)" -K  "project.max-shm-memory=(priv,4GB,deny)" -K "project.max-shm-ids=(priv,1024,deny)" -K "project.max-sem-ids=(priv,1024,deny)" group.mqm
		fi	
		
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1 -p group.mqm
		if [ $? -ne 0 ] 
		then
			abortProceed
		fi
		export FREE_SPACE=$(df -k /var | tail -1 | awk '{print $4}')
	
	;;
	esac
	printLog "\n Checking if there is available space for temporary files on /var ------ "
	if [ $FREE_SPACE -ge 1024000 ]
	then
		printLog "\033[01;32m[  OK  ]\033[00m\n"
	else
		printLog "\033[01;31m[ Failed ]\033[00m\n"
		printLog " At least 1GB of free space are required on /var filesystem to proceed with the installation\n\n"
		return 1
	fi
	
}


function getPackages {
	
	printLog "\n\n--------------------------------------\n"
	printLog " Provide the location of MQ Installer \n"
	printLog "--------------------------------------\n\n"
	printLog "  1 - NFS Installation using Repository [eg: uts2stl0] \n"
	printLog "  2 - LOCAL Installation (MQ Package is locally) \n\n"
	read PACKLOCATION?" Select one option to proceed: "
	
	until [[ $PACKLOCATION = +([1-2]) ]]
	do
		read PACKLOCATION?" Select option 1 or 2 to proceed: "
	done
	
	case $PACKLOCATION in
	
	(1)
	
		printLog "\n Provide the full path name where the BASE package is stored in the repository: "
		read BASEPKGFILES
		while true
		do
		if [ ! -d "$BASEPKGFILES" ]
		then
			printLog "\n Provide a valid MQ BASE path [eg: /sys_apps_01/sys_adm/common/ibm/MQ/Server/Linux/Base/7.1.0.0]: "
			read BASEPKGFILES
		else
			break
		fi
		done
		
		printLog "\n Provide the full path name of MQ Fix Pack or leave in blank if not required: "
		read FIXPACKFILES
		if [ -z "$FIXPACKFILES" ]
		then
			FIXPACKFILES="Not Required"
		else
		while true
		do
			if [ ! -d "$FIXPACKFILES" ]
			then
				printLog "\n Provide a valid MQ FIX path [eg: /sys_apps_01/sys_adm/common/ibm/MQ/Server/Linux/Fix/7.1.0.1 ]: "
				read FIXPACKFILES
			else
				export REMOTEINSTALL=yes
				break
			fi
		done
		fi
		export BASEPACK=$BASEPKGFILES
		export FIXPACK=$FIXPACKFILES
		
	;;
	
	(2)
	
		printLog "\n\n Provide the full path name of MQ BASE package (.tar, gz or .Z): "
		read BASEPACK1

		while true
		do
		if [ ! -f "$BASEPACK1" ]
		then
			printLog "\n Provide a valid MQ BASE package [eg: /var/tmp/MQFULL/CI3CHML-WebSphereMultilingual.tar.Z]: "
			read BASEPACK1
		else
			break
		fi
		done

		printLog "\n Provide the full path name of MQ Fix Pack or leave in blank if not required: "
		read FIXPACK1
		if [ -z "$FIXPACK1" ]
		then
			FIXPACK="Not Required"
		else
		while true
		do
			if [ ! -f "$FIXPACK1" ]
			then
				printLog "\n Provide a valid MQ FIX package [eg: /var/tmp/MQFIX/MQC71_7.1.0.1_LINUXX86-64.tar.gz ]: "
				read FIXPACK1
			else
				break
			fi
		done
		export FIXPACK=$(echo $FIXPACK1 | tr -d ' ')
		mv "$FIXPACK1" "$FIXPACK" > /dev/null 2>&1
		fi

		# REMOVING SPACES
		printLog "\n Removing blank spaces from the package name --------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		export BASEPACK=$(echo $BASEPACK1 | tr -d ' ')
		mv "$BASEPACK1" "$BASEPACK" > /dev/null 2>&1


		printLog " Checking available space to uncompress MQ packages -------------------- "
		FREE_SPACE=$(df -k "$BASEPACK" | tail -1 | awk '{print $3}')
		if [ $FREE_SPACE -ge 512000 ]
		then
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		else
			printLog "\033[01;31m[ Failed ]\033[00m\n\n"
			printLog " At least 512MB of free space are required on $(df -k "$BASEPACK" | tail -1 | awk '{print $7}') filesystem to proceed with the installation\n\n"
			return 1
		fi

		if [ "$PLATFORM" == "SunOS" ]
		then
			BASEPKGTYPE=$(echo "$BASEPACK" | nawk -F '.' '{print $NF}')
		else
			BASEPKGTYPE=$(echo "$BASEPACK" | awk -F '.' '{print $NF}')
		fi
		
		BASEPKGNAME=$(basename "$BASEPACK")
		BASEPKGDIR=$(dirname "$BASEPACK")
		printLog " Preparing files for MQ Installation ----------------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		printLog " Uncompressing bundle packages ----------------------------------------- "

		if [ "$BASEPKGTYPE" == "Z" ]
		then
			[ ! -d "$BASEPKGDIR/BASE_TEMP" ] && mkdir $BASEPKGDIR/BASE_TEMP
			uncompress "$BASEPACK"
			[ $? -ne 0 ] && return 1
			BASEPKGNAME=$(basename "$BASEPACK" | sed s/.Z// )
			BASEPKGTAR=$(ls $BASEPKGDIR | grep $BASEPKGNAME | grep .tar)
			cd $BASEPKGDIR/BASE_TEMP
			tar xvf $BASEPKGDIR/$BASEPKGTAR > /dev/null
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		elif [ "$BASEPKGTYPE" == "tar" ] || [ "$BASEPKGTYPE" == "gz" ]
		then
			[ ! -d "$BASEPKGDIR/BASE_TEMP" ] && mkdir $BASEPKGDIR/BASE_TEMP
			BASEPKGTAR=$(ls $BASEPKGDIR | grep $BASEPKGNAME | grep .tar)
			cd $BASEPKGDIR/BASE_TEMP
			tar xvf $BASEPKGDIR/$BASEPKGTAR > /dev/null
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		else
			printLog " File format not recognized: "$BASEPACK", it must be .tar.gz or .Z file" 
			return 1
		fi
		cd - > /dev/null
		export BASEPKGFILES=$BASEPKGDIR/BASE_TEMP
		export REMOTEINSTALL=no
	;;
	
	esac

	printLog "\n======================================\n"
	printLog " WEBSPHERE MQ INSTALLATION - SUMMARY\n"
	printLog "======================================\n\n"
	printLog " Installation Type: $TYPE \n\n BasePack: $BASEPACK\n\n FixPack: $FIXPACK\n\n Log File: $LOG_FILE\n"
		
	abortProceed
	
}


function installMQServer {
	
	clear
	printLog "\n==========================================\n"
	printLog " WEBSPHERE MQ BASE - INSTALLATION PROCESS\n"
	printLog "==========================================\n\n"
	printLog "\n Checking previous versions installed in the system  -------------------- "
	
	
	case $PLATFORM in 
	
	(AIX)
	
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			/usr/bin/lslpp -L |grep -i mqm
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		fi
				
		printLog "\n Installing WebSphere MQ Server, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$BASEPKGFILES" -f 'gsksa ALL  @@I:gsksa _all_filesets,gskta ALL  @@I:gskta _all_filesets,mqm.base ALL  @@I:mqm.base _all_filesets,mqm.gskit ALL @@I:mqm.gskit _all_filesets,mqm.client ALL  @@I:mqm.client _all_filesets,mqm.java ALL  @@I:mqm.java _all_filesets,mqm.jre  ALL  @@I:mqm.jre _all_filesets,mqm.keyman  ALL  @@I:mqm.keyman _all_filesets,mqm.man.en_US.data  ALL  @@I:mqm.man.en_US.data _all_filesets,mqm.server ALL  @@I:mqm.server _all_filesets,mqm.txclient ALL  @@I:mqm.txclient _all_filesets' '-g' '-X' '-G' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mqm
			printLog "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog " Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
			return 1
		fi
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
		
	;;

	(Linux)
			
		rpm -qa |grep -i mqseries > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			rpm -qa |grep -i mqseries
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"			
		fi
		
		printLog "\n Installing WebSphere MQ Server, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGFILES/mqlicense.sh ] && $BASEPKGFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesServer MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit MQSeriesTXClient"
		for i in $packages; do rpm -ivh $BASEPKGFILES/$i*.rpm 2> /dev/null; done
		if [ $? -eq 0 ]
		then
			printLog "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
			return 1
		fi
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
		
	;;
		
	(SunOS)
	
		pkginfo | grep -i "application mqm" > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			pkginfo | grep -i "application mqm"
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"	
		fi		
		
		printLog "\n Installing WebSphere MQ Server, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGFILES/mqlicense.sh ] && $BASEPKGFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		
		echo "CLASSES=runtime base gskit java jre man samples server sol_client txclient" > /tmp/response_file
		cat <<EOF > /tmp/admin_file
mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default
EOF
		pkgadd -a /tmp/admin_file -r /tmp/response_file -d $BASEPKGFILES mqm >> $LOG_FILE 2>&1
		
		if [ $(pkginfo |grep -i mq | wc -l) -ne 0 ]
        then
        	printLog "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
        else
        	printLog "\n Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
			return 1
       	fi	
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*	
			
	;;
			
	esac
	
	return 0

}

function installMQClient {

	printLog "\n============================================\n"
	printLog " WEBSPHERE MQ CLIENT - INSTALLATION PROCESS\n"
	printLog "============================================\n\n"
	printLog "\n Checking previous versions installed in the system  ------------------- "

	case $PLATFORM in 
	
	(AIX)
		
		/usr/bin/lslpp -L |grep -i mq > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			/usr/bin/lslpp -L |grep -i mq
			printLog "======================================================\n"
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		fi
		
		printLog "\n Installing WebSphere MQ Client, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$BASEPKGFILES" -f '_all_latest' '-g' '-X' '-G' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mq
			printLog "\n $(tput bold)WebSphere MQ Client installation was completed ------------------------ \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Client Installation -------------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
	
	;;

	(Linux)

		rpm -qa |grep -i mqseries > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			rpm -qa |grep -i mqseries
			printLog "======================================================\n"
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"			
		fi
	
		printLog "\n Installing WebSphere MQ Client, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGFILES/mqlicense.sh ] && $BASEPKGFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit"
		for i in $packages; do rpm -ivh $BASEPKGFILES/$i*.rpm; done
		if [ $? -eq 0 ]
		then
			printLog "\n $(tput bold)WebSphere MQ Client installation was completed ------------------------ \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Client Installation -------------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*	
			return 1
		fi
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
		
	;;
		
	(SunOS)
	
		pkginfo | grep -i "application mqm" > /dev/null
		if [ $? -eq 0 ]
		then
			printLog "\033[01;33m[  Warning  ]\033[00m\n\n"
			pkginfo | grep -i "application mqm"
			printLog "======================================================\n"
			abortProceed
		else
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"	
		fi

		echo "CLASSES=runtime base gskit java jre man samples sol_client txclient" > /tmp/response_file
		cat << EOF > /tmp/admin_file
mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default
EOF
		
		printLog "\n Installing WebSphere MQ Client, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGFILES/mqlicense.sh ] && $BASEPKGFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		
		for i in $(ls $BASEPKGFILES | grep .img)
		do 
			pkgadd -n -a /tmp/admin_file -r /tmp/response_file -d $BASEPKGFILES/$i <<EOF >> $LOG_FILE 2>&1
all
EOF
		done
		
		if [ $(pkginfo |grep -i mq | wc -l) -ne 0 ]
        then
        	printLog "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------ \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
        else
        	printLog "\n Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*
			return 1
       	fi	
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $BASEPKGFILES/*	
		
	;;
			
	esac

	return 0
}

function installMQFixPack {
	
	[ "$FIXPACK" == "Not Required" ] && return 0
	
	printLog "\n==============================================\n"
	printLog " WEBSPHERE MQ FIX PACK - INSTALLATION PROCESS\n"
	printLog "==============================================\n\n"
	
	if [ "$REMOTEINSTALL" == "no" ]
	then
		if [ "$PLATFORM" == "SunOS" ]
		then
			FIXPKGTYPE=$(echo "$FIXPACK" | nawk -F '.' '{print $NF}')
		else
			FIXPKGTYPE=$(echo "$FIXPACK" | awk -F '.' '{print $NF}')
		fi
		
		FIXPKGNAME=$(basename "$FIXPACK")
		FIXPKGDIR=$(dirname "$FIXPACK")
		
		printLog " Uncompressing packages ------------------------------------------------ "

		if [ "$FIXPKGTYPE" == "Z" ]
		then
			[ ! -d "$FIXPKGDIR/FIX_TEMP" ] && mkdir $FIXPKGDIR/FIX_TEMP
			uncompress "$FIXPACK"
			[ $? -ne 0 ] && return 1
			FIXPKGNAME=$(basename "$FIXPACK" | sed s/.Z// )
			FIXPKGTAR=$(ls $FIXPKGDIR | grep $FIXPKGNAME | grep .tar)
			cd $FIXPKGDIR/FIX_TEMP
			tar xvf $FIXPKGDIR/$FIXPKGTAR > /dev/null
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		elif [ "$FIXPKGTYPE" == "tar" ] || [ "$FIXPKGTYPE" == "gz" ]
		then
			[ ! -d "$FIXPKGDIR/FIX_TEMP" ] && mkdir $FIXPKGDIR/FIX_TEMP
			FIXPKGTAR=$(ls $FIXPKGDIR | grep $FIXPKGNAME | grep .tar)
			cd $FIXPKGDIR/FIX_TEMP
			tar xvf $FIXPKGDIR/$FIXPKGTAR > /dev/null
			printLog "\033[01;32m[  OK  ]\033[00m\n\n"
		else
			printLog " File format not recognized: "$FIXPACK", it must be .tar.gz or .Z file" 
			return 1
		fi
		cd - > /dev/null
		export FIXPACKFILES=$FIXPKGDIR/FIX_TEMP
	fi

	case $PLATFORM in 
	
	(AIX)
		
		printLog " Applying MQ Fix Pack, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$FIXPACKFILES" -f 'gsksa ALL  @@I:gsksa _all_filesets,gskta ALL  @@I:gskta _all_filesets,mqm.base ALL  @@I:mqm.base _all_filesets,mqm.gskit ALL @@I:mqm.gskit _all_filesets,mqm.client ALL  @@I:mqm.client _all_filesets,mqm.java ALL  @@I:mqm.java _all_filesets,mqm.jre  ALL  @@I:mqm.jre _all_filesets,mqm.keyman  ALL  @@I:mqm.keyman _all_filesets,mqm.man.en_US.data  ALL  @@I:mqm.man.en_US.data _all_filesets,mqm.server ALL  @@I:mqm.server _all_filesets,mqm.txclient ALL  @@I:mqm.txclient _all_filesets' '-c' '-N' '-g' '-X' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mq
			printLog "\n $(tput bold)WebSphere MQ Fix Pack installation was completed ---------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Fix Pack Installation --------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $FIXPACKFILES/*
			return 1
		fi
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $FIXPACKFILES/*
	
	;;

	(Linux)
	
		printLog " Applying MQ Fix Pack, this operation may take several minutes to complete \n\n"
		[ -f $FIXPACKFILES/mqlicense.sh ] && $FIXPACKFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesServer MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit MQSeriesTXClient"
		for i in $packages; do rpm -ivh $FIXPACKFILES/$i*.rpm; done 
		if [ $? -eq 0 ]
		then
			printLog "\n $(tput bold)WebSphere MQ Fix Pack installation was completed ---------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Fix Pack Installation --------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ "$REMOTEINSTALL" == "no" ] && rm -rf $FIXPACKFILES/*
			return 1
		fi
		[ "$REMOTEINSTALL" == "no" ] && rm -rf $FIXPACKFILES/*
	
	;;
		
	(SunOS)
	
		printLog " Applying MQ Fix Pack, this operation may take several minutes to complete \n\n"
		[ -f $FIXPACKFILES/mqlicense.sh ] && $FIXPACKFILES/mqlicense.sh -accept >> $LOG_FILE 2>&1
		
		for i in $(ls $FIXPACKFILES | grep .img)
		do 
			pkgadd -n -a /tmp/admin_file -r /tmp/response_file -d $FIXPACKFILES/$i <<EOF >> $LOG_FILE 2>&1
all
EOF
		done
		if [ $? -eq 0 ]
		then
			printLog "\n $(tput bold)WebSphere MQ Fix Pack installation was completed ---------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printLog "\n Errors were found during MQ Fix Pack Installation --------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			[ -w $FIXPACKFILES ] && rm -rf $FIXPACKFILES/*
			return 1
		fi
		[ -w $FIXPACKFILES ] && rm -rf $FIXPACKFILES/*
	;;
			
	esac
	
	return 0

}

function initScripts {

	printLog " Configuring Init Scripts and Files ------------------------------------ "
	
	case $PLATFORM in 
	
	(AIX)
	
		if [ ! -f /etc/rc.d/init.d/S98WMQ ]
		then
			cp /sys_apps_01/sys_adm/common/AutomationScripts/MQ/S98WMQ /etc/rc.d/init.d
			chmod +x /etc/rc.d/init.d/S98WMQ
			ln -sf /etc/rc.d/init.d/S98WMQ /etc/rc.d/rc3.d/S98WMQ
			ln -sf /etc/rc.d/init.d/S98WMQ /etc/rc.d/rc2.d/S98WMQ
			ln -sf /etc/rc.d/init.d/S98WMQ /etc/rc.d/rc0.d/S98WMQ
		fi
		printLog "\033[01;32m[  OK  ]\033[00m\n\n"
	;;

	(Linux)
	
		if [ ! -f /etc/init.d/S98WMQ ]
		then
			cp /sys_apps_01/sys_adm/common/AutomationScripts/MQ/S98WMQ /etc/init.d
			chmod +x /etc/rc.d/init.d/S98WMQ
			chkconfig S98WMQ on
			ln -sf /etc/init.d/S98WMQ /etc/rc.d/rc1.d/S98WMQ
			ln -sf /etc/init.d/S98WMQ /etc/rc.d/rc0.d/S98WMQ
		fi
		printLog "\033[01;32m[  OK  ]\033[00m\n\n"
	
	;;
		
	(SunOS)

		if [ ! -f /etc/init.d/S98WMQ ]
		then
			cp /sys_apps_01/sys_adm/common/AutomationScripts/MQ/S98WMQ /etc/init.d
			chmod +x /etc/init.d/S98WMQ
			ln -sf /etc/init.d/S98WMQ /etc/rc3.d/S98WMQ
			ln -sf /etc/init.d/S98WMQ /etc/rc2.d/S98WMQ
			ln -sf /etc/init.d/S98WMQ /etc/rc1.d/S98WMQ
			ln -sf /etc/init.d/S98WMQ /etc/rc0.d/S98WMQ
		fi
		printLog "\033[01;32m[  OK  ]\033[00m\n\n"
	;;
			
	esac
	
}

function postInstallMQ {

	printLog "\n=============================\n"
	printLog " WEBSPHERE MQ - POST SCRIPTS\n"
	printLog "=============================\n\n"
	
	printLog "\n Removing links to 32 Bit libs using "dltmqlnk" -------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
	[ -f /usr/mqm/bin/dltmqlnk ] && /usr/mqm/bin/dltmqlnk >> $LOG_FILE 2>&1
	[ -f /opt/mqm/bin/dltmqlnk ] && /opt/mqm/bin/dltmqlnk >> $LOG_FILE 2>&1
	printLog " Setting MQ installation as default ------------------------------------ \033[01;32m[  OK  ]\033[00m\n\n"
	[ -f /opt/mqm/bin/setmqinst ] && /opt/mqm/bin/setmqinst -i -n Installation1 >> $LOG_FILE 2>&1
	[ -f /usr/mqm/bin/setmqinst ] && /usr/mqm/bin/setmqinst -i -n Installation1 >> $LOG_FILE 2>&1
	
	printLog " $(tput bold)IBM MQ has been installed and updated in the system ------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n\n"
	printLog "\033[01;37m$(date +'%d %b %Y')\tINSTALLATION SUMMARY \t $HOSTNAME\n"
	printLog "======================================================\n"
	printLog "$(dspmqver)\n"
	printLog "======================================================\nLOG: $LOG_FILE$(tput sgr0)\033[00m\n\n\n"
	
}

function checkConfig {

	printLog "\n================================\n"
	printLog " WEBSPHERE MQ - COMPLIANCE CHECK\n"
	printLog "================================\n\n"

	printLog " Checking if MQ is installed in the system -----------------------------   "
	if [ ! -f /usr/bin/dspmqver ] 
	then
		printLog "\033[00;31mFAILED\033[00m --> Message Queue is not installed in the system\n\n"
		return 1
	else
		printLog "\033[00;32mDONE\033[00m\n\n"
	fi
	
	printLog " Verifying the existence of MQ User in the system ----------------------   "
	grep "^mqm:" /etc/passwd > /dev/null
	if [ $? -eq 0 ]
	then
		printLog "\033[00;32mDONE\033[00m\n\n"
	else
		printLog "\033[00;31mFAILED\033[00m --> mqm user is not created\n\n"
	fi
	
	printLog " Checking the presence of dedicated filesystems for MQ -----------------   "
	df -k | grep "/var/mqm" > /dev/null || df -k | grep "/opt/mqm" || df -k | grep "/usr/mqm" > /dev/null
	if [ $? -eq 0 ]
	then
		printLog "\033[00;32mDONE\033[00m\n\n"
	else
		printLog "\033[00;31mFAILED\033[00m --> There isn't a dedicated Filesystem for MQ \n\n"
	fi
	
	case $PLATFORM in 
	
	(AIX)
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1
		if [ $? -ne 0 ] 
		then
			printLog " Fixing current installation settings as per IBM's recomendation\n"
			abortProceed
			printLog " Configuring Kernel Settings ------------------------------------------- \033[00;32m  DONE  \033[00m\n\n"
			CUR_MAXUPROC=$(lsattr -El sys0 -a maxuproc 2>/dev/null | awk '{print $2}')
			if [ "$CUR_MAXUPROC" -lt "1024" ]
			then
				chdev -l sys0 -a maxuproc='1024' >> $LOG_FILE 2>&1
			fi
		fi

		
	;;
	
	(Linux)
	
	
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1
		if [ $? -ne 0 ] 
		then
			printLog "\n\n Fixing current installation settings as per IBM's recomendation"
			abortProceed
			printLog " Configuring Kernel Settings ------------------------------------------- \033[00;32m  DONE  \033[00m\n"
			cp /etc/sysctl.conf	/etc/sysctl.conf_$(date +'%d.%b.%Y-%I.%M%p')
			
			grep -q "kernel.msgmni" /etc/sysctl.conf > /dev/null 2>&1
			[ $? -ne 0 ] && echo "kernel.msgmni = 1024" >> /etc/sysctl.conf
			
			grep -q "kernel.shmmni" /etc/sysctl.conf > /dev/null 2>&1
			[ $? -ne 0 ] && echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
			
			grep -q "kernel.sem" /etc/sysctl.conf > /dev/null 2>&1
			[ $? -ne 0 ] && echo "kernel.sem = 500 256000 250 2014" >> /etc/sysctl.conf
			
			grep -q "fs.file-max" /etc/sysctl.conf > /dev/null 2>&1
			[ $? -ne 0 ] && echo "fs.file-max = 524288" >> /etc/sysctl.conf
			
			sysctl -p >> $LOG_FILE 2>&1
		fi

	;;
	
	(SunOS)
		
		/sys_apps_01/sys_adm/common/AutomationScripts/MQ/mqconfig -v 7.1
		if [ $? -ne 0 ] 
		then
			printLog " Fixing current installation settings as per IBM's recomendation\n"
			abortProceed
			printLog " Configuring Kernel Settings ------------------------------------------- \033[00;32m  DONE  \033[00m\n\n"
			grep group.mqm /etc/project > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				projadd -c "WebSphere MQ default settings" -K "process.max-file-descriptor=(basic,10000,deny)" -K  "project.max-shm-memory=(priv,4GB,deny)" -K "project.max-shm-ids=(priv,1024,deny)" -K "project.max-sem-ids=(priv,1024,deny)" group.mqm
			fi
		fi			
		
			
	;;
	esac
	
	printLog "\n\n======================================================\n"
	printLog "$(dspmqver)\n"
	printLog "======================================================\nLOG: $LOG_FILE$(tput sgr0)\033[00m\n\n\n"
}

##########
#  MAIN  #
##########

		clear
		printLog "================================================================================\n"
		printLog "\t\t\t$(tput bold)UNIX SERVICES$(tput sgr0)\n"
		printLog "================================================================================\n"
		printLog "\t$(tput bold)\tWEBSPHERE MESSAGE QUEUE INSTALLATION PROCESS - v1.0.3$(tput sgr0)\n"
		printLog "\tHOSTNAME:$(tput bold) $HOSTNAME $(tput sgr0) \t OPERATING SYSTEM:$(tput bold) $PLATFORM$(tput sgr0) \t\tARCH:$(tput bold) $ARCH$(tput sgr0)\n"
		printLog "================================================================================\n\n"
		printLog " 1 - Uninstall WebSphere Message Queue\n"
		printLog " 2 - Install WebSphere Message Queue Server\n"
		printLog " 3 - Install WebSphere Message Queue Client\n"
		printLog " 4 - Evaluate Current WebSphere Message Queue Settings\n\n"
		
		read OPTION?" Select one option to proceed: "
		
		until [[ $OPTION = +([1-4]) ]]
		do
			read OPTION?"Select an option from 1 to 4 to proceed: "
		done
		
		case $OPTION in
		
		(1)
		
			uninstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
							
		;;
		
		(2)
			TYPE="Message Queue Server"
			
			preInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			getPackages
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			installMQServer
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			installMQFixPack
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			initScripts
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			postInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
		;;
		
		(3)
			TYPE="Message Queue Client"
			
			preInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
		
			getPackages
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			installMQClient
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			installMQFixPack
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			postInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
		;;
		
		(4)
		
			checkConfig
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
		;;
			
		esac
		
		
