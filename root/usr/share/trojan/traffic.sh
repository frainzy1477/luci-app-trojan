#!/bin/bash /etc/rc.common
. /lib/functions.sh
Core=/usr/bin/trojan-go
NAME=trojan

uci_get_by_name() {
	local ret=$(uci get $NAME.$1.$2 2>/dev/null)
	echo ${ret:=$3}
}

uci_get_by_type() {
	local ret=$(uci get $NAME.@$1[0].$2 2>/dev/null)
	echo ${ret:=$3}
}

#global_config=$(uci_get_by_type global ctype 2>/dev/null)
#if [ "${global_config}" -eq 1 ];then
ACTIVE_SERVER=$(uci_get_by_type global global_server 2>/dev/null)
password=$(uci_get_by_name $ACTIVE_SERVER password 2>/dev/null)
#else
#	password=`awk '/password/ {print $0}' /etc/trojan/config.json | sed 's/\[//g' | sed 's/\]//g'  | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
#fi

if [ "$?" -eq "0" ]; then
	if [ ! -z $password ];then
		speed=`${Core} -api-addr 127.0.0.1:57721 -api traffic -target-password "${password}"  | sed 's/{//g' | sed 's/\}//g'  | sed 's/\"//g' | grep "speed_current:" | awk -F 'speed_current:' '{print $2}'  | grep ":" | awk -F ':' '{print $2 " " $3}' | sed 's/download_speed //g'`
		if [ $speed ];then
		  echo "0,${speed}"
		else
		  echo "0,0,0"
		fi
	else
	  echo "0,0,0"
	fi
fi


