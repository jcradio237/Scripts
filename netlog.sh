#!/bin/bash
############################################################
#  This script will automate the process of                #
#  Logging Calls on a Pi-Star Hotpot                       #
#                                                          #
#  VE3RD                                      2021/07/04   #
############################################################
set -o errexit
set -o pipefail
set -e
sudo mount -o remount,rw /
callstat="dup"
callinfo="No Info"
lastcall=""
netcont="$1"
dur=$((0))

#echo -e '\e[1;40m'
#echo -e '\e[1;44m'


sudo touch /home/pi-star/netlog.sh
 
if [ ! "$1" ] || [ "$1" == "new" ]; then
	echo "No Net Controller Specified"
	netcont="N/A"
else
	echo "Net Controller is $netcont"
fi

if [ "$1" == "new" ] || [ "$2" == "new" ] || [ ! -f /home/pi-star/netlog.log ]; then
	date > /home/pi-star/netlog.log
fi


function userinfo(){
 	line=$(sed -n '/'"$call"',/p' /usr/local/etc/stripped.csv | tail -n1)	
#echo "$line"
	if [ line ]; then
		name=$(echo "$line" | cut -d "," -f 3)
		city=$(echo "$line"| cut -d "," -f 5)
		state=$(echo "$line" | cut -d "," -f 6)
		country=$(echo "$line" | cut -d "," -f 7)
	else
		callinfo="No Info"
		name=""
		city=""
		state=""
		country=""
	fi
#echo userinfo
}

function checkcall(){
	ck=$(sed -n '/'"$call"'/p' /home/pi-star/netlog.log | cut -d "," -f 2)
#        echo "Found Call x""$ck""x"
	if [ "$ck" ]; then
		ckt=$(sed -n '/'"$call"'/p' /home/pi-star/netlog.log | cut -d "," -f 1)
		callstat="Dup"
        else
#		echo "New Call $call"
		callstat="New"
	fi
	
#echo CheckCall
}

function Logit(){
	dts=$(zdump EST+4 | cut -d " " -f 7)
	## Write New Call to Screen

	echo -e '\e[0;33m'"$dts EST/DST -- $call --  $name, $city, $state, $country  Dur:$durt"" sec"  PL:"$pl"	

	sudo mount -o remount,rw /
	## Write New Call to Log File
	echo "$dts EST/DST,$call,$name,$city,$state,$country " >> /home/pi-star/netlog.log
}

while true
do 

#	f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 | cut -d " " -f 10 )
	f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 )

#	echo "$f1"

#	nline=$(grep -w header "$f1" | tail -n 1)
	nline2=$(grep -w transmission "$f1" | tail -n 1)
#	call=$(echo "$nline" | cut -d " " -f 12 )
	call2=$(echo "$nline2" | cut -d " " -f 14 )
	durt=$(echo "$nline2" | cut -d " " -f 18 )
	pl=$(echo "$nline2" | cut -d " " -f 20 )
	dur=$(printf "%1.0f\n" $durt)
	call=$call2
#	echo "$call"
	
	dts=$(zdump EST+4 | cut -d " " -f 7)

	if [ "$lastcall" != "$call" ]; then
		if [ "$call" == "$netcont" ]; then

			echo -e '\e[1;31m'"-------------------- $dts  Net Control $netcont "
			echo -e "-------------------- $dts  Net Control $netcont "

			name=""
			city=""
			state=""
			country=""
			callstat="NC"		
		else
			userinfo
			checkcall
		fi

		if [ $dur -lt 2 ]; then
			echo -e '\e[0;36m'"KeyUp $dts $call $name $durt"" sec"
			callstat=""
		fi

		if [ "$callstat" == "New" ] && [ "$call" != "$netcont" ]; then
			Logit
		fi
		if [ "$callstat" == "Dup" ]; then
			## Write Duplicate Info to Screen
			echo  -e '\e[1;32m'"Duplicate -- $ckt -- $call  $name  Dur:$durt"" sec  PL: $pl"
		fi
		

	fi

	lastcall="$call"
	sleep 1
done