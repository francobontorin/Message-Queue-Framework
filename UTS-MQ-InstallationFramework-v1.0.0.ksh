#!/bin/ksh
################################################################################
# 			  UTS - UNIX TECHNICAL SERVICES
# Copyright (c) 2012 Franco Bontorin.  All rights reserved.
#
# This software is only to be used for the purpose for which it has been
# provided.  No part of it is to be reproduced, disassembled, transmitted
# stored in a retrieval system nor translated, in any human or computer
# language in any way or for any other purpose whatsoever without the
# prior written consent of Franco Bontorin.
#
# Documentation
# ==============================================================================
# This script is used to automatically installs IBM WebSphere Message Queue in
# AIX, Solaris and Linux (RHEL)
# ==============================================================================
#
# Version Control
# ==============================================================================
#	Ver 1.0.0 - Created by Franco Bontorin 
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
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n\n"
		read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 				
		until [[ "$enterKey" = +([Y|y|A|a]) ]]
		do
			read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 
		done
		if [ "$enterKey" == "A" ] || [ "$enterKey" == "a" ]
		then
			printLog "\n Uninstall process aborted by the user\n\n"
			return 1					
		fi
		
		printLog "\n================================================================================\n"
		printLog "\n Uninstalling MQ Packages, this may take several minutes to complete \n\n"
		/usr/sbin/installp -C mqm* >> $LOG_FILE 2>&1
		/usr/sbin/installp -u mqm* >> $LOG_FILE 2>&1
		if [ $? -eq 0 ]
		then
			printLog " IBM MQ Uninstall Process finished -------------------------------------- \033[01;32m[  OK  ]\033[00m \n\n"
		else
			printLog " Errors happened during MQ Uninstall Process -------------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
					
		
	;;
 
	(Linux)
	
		printLog " Identifying MQ Packages installed in the system ----------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		rpm -qa |grep -i mqseries >> $LOG_FILE 2>&1
		rpm -qa |grep -i mqseries
		[ $? -ne 0 ] && printLog " IBM MQ is not installed on $HOSTNAME ---------------------------------- \033[01;32m[  OK  ]\033[00m\n\n" && return 1
				
		printLog "\n================================================================================\n"
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n\n"
		read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 				
		until [[ "$enterKey" = +([Y|y|A|a]) ]]
		do
			read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 
		done
		if [ "$enterKey" == "A" ] || [ "$enterKey" == "a" ]
		then
			printLog "\n Uninstall process aborted by the user\n\n"
			return 1					
		fi
		
		printLog "\n================================================================================\n"
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
		printLog " IBM MQ Uninstall Process finished -------------------------------------- \033[01;32m[  OK  ]\033[00m \n\n"
				
	;;
	
	(SunOS)
	
		printLog " Identifying MQ Packages installed in the system ----------------------- \033[01;32m[  OK  ]\033[00m\n\n"
		pkginfo | grep -i "application mqm" >> $LOG_FILE 2>&1; pkginfo | grep -i "application mqm"
		[ $? -ne 0 ] && printLog " IBM MQ is not installed on $HOSTNAME ---------------------------------- \033[01;32m[  OK  ]\033[00m\n\n" && return 1

		printLog "\n================================================================================\n"
		printLog "\n$(tput bold) ATTENTION: All these packages will be removed from the system$(tput sgr0)\n\n"
		read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 
		until [[ "$enterKey" = +([Y|y|A|a]) ]]
		do
			read enterKey?" Press < Y > to proceed with MQ Uninstall Process or < A > to abort:  " 
		done
		if [ "$enterKey" == "A" ] || [ "$enterKey" == "a" ]
		then
			printLog "\n Uninstall process aborted by the user\n\n"
			return 1					
		fi
		printLog "\n================================================================================\n"
		printLog " \n Uninstalling MQ Packages, this may take several minutes to complete \n\n"
		#yes | pkgrm mqm >> $LOG_FILE 2>&1
		#yes | pkgrm mqm-06-00-02-07 >> $LOG_FILE 2>&1
		#yes | pkgrm mqm-06-00-02-00 >> $LOG_FILE 2>&1
		#yes | pkgrm mqm-06-00-02-04 >> $LOG_FILE 2>&1
		#yes | pkgrm mqm-07-00-01-03 >> $LOG_FILE 2>&1
		#[ $? -ne 0 ] && return 1
		
	;;
	
	esac

}
	

function preInstallMQ {


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
		printf "\033[01;32m[  OK  ]\033[00m"
	else
		printf "\033[01;31m[ Failed ]\033[00m --> mqm user NOT created, please check with GIS and try again\n\n"
		return 1
	fi
	
	printLog "\n\n Checking the presence of dedicated filesystems for MQ ----------------- "
	df -k | grep "/var/mqm" > /dev/null || df -k | grep "/opt/mqm" || df -k | grep "/usr/mqm" > /dev/null
	if [ $? -eq 0 ]
	then
		printf "\033[01;32m[  OK  ]\033[00m"
	else
		printf "\033[01;31m[ Failed ]\033[00m --> MQ Filesystem NOT created, please create it and try again\n\n"
		return 1
	fi	

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
	FIXPACK=$(echo $FIXPACK1 | tr -d ' ')
	mv "$FIXPACK1" "$FIXPACK" > /dev/null 2>&1
	fi
	
	# REMOVING SPACES
	printLog "\n Removing blank spaces from the package name --------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
	BASEPACK=$(echo $BASEPACK1 | tr -d ' ')
	mv "$BASEPACK1" "$BASEPACK" > /dev/null 2>&1
	
	
	printLog " Checking available space to uncompress MQ packages -------------------- "
	FREE_SPACE=$(df -k "$BASEPACK" | tail -1 | awk '{print $3}')
	if [ $FREE_SPACE -ge 512000 ]
	then
		printf "\033[01;32m[  OK  ]\033[00m\n\n"
	else
		printf "\033[01;31m[ Failed ]\033[00m\n\n"
		printLog " At least 512MB of free space are required on $(df -k "$BASEPACK" | tail -1 | awk '{print $7}') filesystem to proceed with the installation\n\n"
		return 1
	fi
	
	BASEPKGTYPE=$(echo "$BASEPACK" | awk -F '.' '{print $NF}')
	BASEPKGDIR=$(dirname "$BASEPACK")
	BASEPKGNAME=$(basename "$BASEPACK")
	printLog " Preparing files for MQ Installation ----------------------------------- \033[01;32m[  OK  ]\033[00m\n\n"
	printLog " Uncompressing bundle packages ----------------------------------------- "
	
	if [ "$BASEPKGTYPE" == "Z" ]
	then
		[ ! -d "$BASEPKGDIR/BASE_TEMP" ] && mkdir $BASEPKGDIR/BASE_TEMP
		uncompress "$BASEPACK"
		[ $? -ne 0 ] && return 1
		BASEPKGTAR=$(ls $BASEPKGDIR | grep $BASEPKGNAME | grep .tar)
		cd $BASEPKGDIR/BASE_TEMP
		tar xvf $BASEPKGDIR/$BASEPKGTAR > /dev/null
		printf "\033[01;32m[  OK  ]\033[00m\n\n"
	elif [ "$BASEPKGTYPE" == "tar" ] || [ "$BASEPKGTYPE" == "gz" ]
	then
		[ ! -d "$BASEPKGDIR/BASE_TEMP" ] && mkdir $BASEPKGDIR/BASE_TEMP
		BASEPKGTAR=$(ls $BASEPKGDIR | grep $BASEPKGNAME | grep .tar)
		cd $BASEPKGDIR/BASE_TEMP
		tar xvf $BASEPKGDIR/$BASEPKGTAR > /dev/null
		printf "\033[01;32m[  OK  ]\033[00m\n\n"
	else
		printLog " File format not recognized: "$BASEPACK", it must be .tar.gz or .Z file" 
		return 1
	fi
	cd - > /dev/null
	
	# Checking Kernel Settings (To be done with the MQ Team)
	printLog " Checking Kernel settings ---------------------------------------------- \033[01;32m[  OK  ]\033[00m\n\n "
	
	
	
	printLog "\n======================================\n"
	printLog " WEBSPHERE MQ INSTALLATION - SUMMARY\n"
	printLog "======================================\n\n"
	printLog " Installation Type: $TYPE \n\n BasePack: $BASEPACK\n\n FixPack: $FIXPACK\n\n Log File: $LOG_FILE\n\n"
	printLog "======================================\n\n"
	
	read enterKey?" Press < Y > to proceed with MQ Install or < A > to abort:  " 
	until [[ "$enterKey" = +([Y|y|A|a]) ]]
	do
		read enterKey?" Press < Y > to proceed with MQ Install or < A > to abort:  " 
	done
	if [ "$enterKey" == "A" ] || [ "$enterKey" == "a" ]
	then
		printLog "\n Install process aborted by the user\n\n"
		return 1					
	fi
	
}

	
			
function installMQServer {
	
	clear
	printLog "\n==========================================\n"
	printLog " WEBSPHERE MQ BASE - INSTALLATION PROCESS\n"
	printLog "==========================================\n\n"
	
	case $PLATFORM in 
	
	(AIX)
		
		printLog "\n Installing WebSphere MQ Server, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$BASEPKGDIR/BASE_TEMP" -f 'gsksa ALL  @@I:gsksa _all_filesets,gskta ALL  @@I:gskta _all_filesets,mqm.base ALL  @@I:mqm.base _all_filesets,mqm.gskit ALL @@I:mqm.gskit _all_filesets,mqm.client ALL  @@I:mqm.client _all_filesets,mqm.java ALL  @@I:mqm.java _all_filesets,mqm.jre  ALL  @@I:mqm.jre _all_filesets,mqm.keyman  ALL  @@I:mqm.keyman _all_filesets,mqm.man.en_US.data  ALL  @@I:mqm.man.en_US.data _all_filesets,mqm.server ALL  @@I:mqm.server _all_filesets,mqm.txclient ALL  @@I:mqm.txclient _all_filesets' '-g' '-X' '-G' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mq
			printf "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------ \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf " Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
		rm -rf $BASEPKGDIR/BASE_TEMP/*
	
	;;

	(Linux)
	
		printLog "\n Installing WebSphere MQ Server, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGDIR/BASE_TEMP/mqlicense.sh ] && $BASEPKGDIR/BASE_TEMP/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesServer MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit MQSeriesTXClient"
		for i in $packages; do rpm -ivh $BASEPKGDIR/BASE_TEMP/$i*.rpm 2> /dev/null; done
		if [ $? -eq 0 ]
		then
			printf "\n $(tput bold)WebSphere MQ Base Package installation was completed ------------------ \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf "\n Errors were found during MQ Base Package Installation ---------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
		rm -rf $BASEPKGDIR/BASE_TEMP/*
		
	;;
		
	(SunOS)
		
	;;
			
	esac	

}

function installMQClient {

	printLog "\n==========================================\n"
	printLog " WEBSPHERE MQ CLIENT - INSTALLATION PROCESS\n"
	printLog "============================================\n\n"

	case $PLATFORM in 
	
	(AIX)
		
		printLog "\n Installing WebSphere MQ Client, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$BASEPKGDIR/BASE_TEMP" -f '_all_latest' '-g' '-X' '-G' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mq
			printf "\n $(tput bold)WebSphere MQ Client installation was completed -------------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf "\n Errors were found during MQ Client Installation -------------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
	
	;;

	(Linux)

		printLog "\n Installing WebSphere MQ Client, this operation may take several minutes to complete \n\n"
		[ -f $BASEPKGDIR/BASE_TEMP/mqlicense.sh ] && $BASEPKGDIR/BASE_TEMP/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit"
		for i in $packages; do rpm -ivh $BASEPKGDIR/BASE_TEMP/$i*.rpm; done
		if [ $? -eq 0 ]
		then
			printf "\n $(tput bold)WebSphere MQ Client installation was completed -------------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf "\n Errors were found during MQ Client Installation -------------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
		
	;;
		
	(SunOS)
		
	;;
			
	esac
}

function installMQFixPack {
	
	[ "$FIXPACK" == "Not Required" ] && return 0
	
	printLog "\n==============================================\n"
	printLog " WEBSPHERE MQ FIX PACK - INSTALLATION PROCESS\n"
	printLog "==============================================\n\n"
	
	FIXPKGTYPE=$(echo "$FIXPACK" | awk -F '.' '{print $NF}')
	FIXPKGDIR=$(dirname "$FIXPACK")
	FIXPKGNAME=$(basename "$FIXPACK")
	
	printLog " Uncompressing packages ------------------------------------------------ "
	
	if [ "$FIXPKGTYPE" == "Z" ]
	then
		[ ! -d "$FIXPKGDIR/FIX_TEMP" ] && mkdir $FIXPKGDIR/FIX_TEMP
		uncompress "$FIXPACK"
		[ $? -ne 0 ] && return 1
		FIXPKGTAR=$(ls $FIXPKGDIR | grep $FIXPKGNAME | grep .tar)
		cd $FIXPKGDIR/FIX_TEMP
		tar xvf $FIXPKGDIR/$FIXPKGTAR > /dev/null
		printf "\033[01;32m[  OK  ]\033[00m\n\n"
	elif [ "$FIXPKGTYPE" == "tar" ] || [ "$FIXPKGTYPE" == "gz" ]
	then
		[ ! -d "$FIXPKGDIR/FIX_TEMP" ] && mkdir $FIXPKGDIR/FIX_TEMP
		FIXPKGTAR=$(ls $FIXPKGDIR | grep $FIXPKGNAME | grep .tar)
		cd $FIXPKGDIR/FIX_TEMP
		tar xvf $FIXPKGDIR/$FIXPKGTAR > /dev/null
		printf "\033[01;32m[  OK  ]\033[00m\n\n"
	else
		printLog " File format not recognized: "$FIXPACK", it must be .tar.gz or .Z file" 
		return 1
	fi
	cd - > /dev/null	

	case $PLATFORM in 
	
	(AIX)
		
		printLog " Applying MQ Fix Pack, this operation may take several minutes to complete \n\n"
		/usr/lib/instl/sm_inst installp_cmd -a -Q -d "$FIXPKGDIR/FIX_TEMP" -f 'gsksa ALL  @@I:gsksa _all_filesets,gskta ALL  @@I:gskta _all_filesets,mqm.base ALL  @@I:mqm.base _all_filesets,mqm.gskit ALL @@I:mqm.gskit _all_filesets,mqm.client ALL  @@I:mqm.client _all_filesets,mqm.java ALL  @@I:mqm.java _all_filesets,mqm.jre  ALL  @@I:mqm.jre _all_filesets,mqm.keyman  ALL  @@I:mqm.keyman _all_filesets,mqm.man.en_US.data  ALL  @@I:mqm.man.en_US.data _all_filesets,mqm.server ALL  @@I:mqm.server _all_filesets,mqm.txclient ALL  @@I:mqm.txclient _all_filesets' '-c' '-N' '-g' '-X' '-Y' >> $LOG_FILE
		/usr/bin/lslpp -L |grep -i mqm > /dev/null
		if [ $? -eq 0 ]
		then
			/usr/bin/lslpp -L |grep -i mq
			printf "\n $(tput bold)WebSphere MQ Fix Pack installation was completed ---------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf "\n Errors were found during MQ Fix Pack Installation --------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
		rm -rf $FIXPKGDIR/FIX_TEMP/*
	
	;;

	(Linux)
	
		printLog " Applying MQ Fix Pack, this operation may take several minutes to complete \n\n"
		[ -f $FIXPKGDIR/FIX_TEMP/mqlicense.sh ] && $$FIXPKGDIR/FIX_TEMP/mqlicense.sh -accept >> $LOG_FILE 2>&1
		packages="MQSeriesRuntime MQSeriesSDK MQSeriesSamples MQSeriesMan MQSeriesServer MQSeriesClient MQSeriesJava MQSeriesJRE MQSeriesGSKit MQSeriesTXClient"
		for i in $packages; do rpm -ivh $FIXPKGDIR/FIX_TEMP/$i*.rpm; done 
		if [ $? -eq 0 ]
		then
			printf "\n $(tput bold)WebSphere MQ Fix Pack installation was completed ---------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n"
		else
			printf "\n Errors were found during MQ Fix Pack Installation --------------------- \033[01;31m[ Failed ]\033[00m\n\n"
			return 1
		fi
		rm -rf $FIXPKGDIR/FIX_TEMP/*
	
	;;
		
	(SunOS)
		
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
	
	printLog " Configuring Init Scripts and Files ------------------------------------ \033[01;32m[  OK  ]\033[00m\n\n"
	printLog " $(tput bold)IBM MQ has been installed and updated in the system ------------------- \033[01;32m[  OK  ]\033[00m$(tput sgr0)\n\n\n"
	printLog "\033[01;37m$(date +'%d %b %Y')\tINSTALLATION SUMMARY \t $HOSTNAME\n"
	printLog "======================================================\n"
	printLog "$(dspmqver)\n"
	printLog "======================================================\nLOG: $LOG_FILE$(tput sgr0)\033[00m\n\n\n"
	
}

	
	
	
##########
#  MAIN  #
##########

		clear
		printLog "================================================================================\n"
		printLog "\t\t\t$(tput bold)UTS - UNIX TECHNICAL SERVICES$(tput sgr0)\n"
		printLog "\tCopyright (c) 2012 Franco Bontorin - All rights reserved\n"
		printLog "================================================================================\n"
		printLog "\t$(tput bold)\tWEBSPHERE MESSAGE QUEUE INSTALLATION PROCESS - v1.0.0$(tput sgr0)\n"
		printLog "\tHOSTNAME:$(tput bold) $HOSTNAME $(tput sgr0) \t OPERATING SYSTEM:$(tput bold) $PLATFORM$(tput sgr0) \t\tARCH:$(tput bold) $ARCH$(tput sgr0)\n"
		printLog "================================================================================\n\n"
		printLog " 1 - Uninstall a previous version of WebSphere Message Queue\n"
		printLog " 2 - Install WebSphere Message Queue Server\n"
		printLog " 3 - Install WebSphere Message Queue Client\n\n"
		read OPTION?" Select one option to proceed: "
		
		until [[ $OPTION = +([1-3]) ]]
		do
			read OPTION?"Select an option from 1 to 3 to proceed: "
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
			
			installMQServer
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			installMQFixPack
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			postInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
		;;
		
		(3)
			TYPE="Message Queue Client"
			
			preInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
		
			installMQClient
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
			postInstallMQ
			[ $? -ne 0 ] && printLog " LOG_FILE: $(tput bold)$LOG_FILE $(tput sgr0)\n\n" && exit 1
			
		;;
			
		esac
		
		
