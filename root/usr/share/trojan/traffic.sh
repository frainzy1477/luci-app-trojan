#!/bin/bash /etc/rc.common
. /lib/functions.sh

password=`awk '/password/ {print $0}' /etc/trojan/trojan.json | sed 's/\[//g' | sed 's/\]//g'  | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
if [ "$?" -eq "0" ]; then
if [ ! -z $password ];then 

  speed=`/etc/trojan/trojan -api-addr 127.0.0.1:57721 -api traffic -target-password "${password}"  | sed 's/{//g' | sed 's/\}//g'  | sed 's/\"//g' | grep "speed_current:" | awk -F 'speed_current:' '{print $2}'  | grep ":" | awk -F ':' '{print $2 " " $3}' | sed 's/download_speed //g'
`
if [ $speed ];then
  echo "0,${speed}"
else
  echo "0,0,0"
fi
else
  echo "0,0,0"
fi
fi


