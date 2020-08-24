#!/bin/bash /etc/rc.common
. /lib/functions.sh

password=`awk '/password/ {print $0}' /etc/trojan/trojan.json | sed 's/\[//g' | sed 's/\]//g'  | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
if [ "$?" -eq "0" ]; then
if [ ! -z $password ];then

  traffic=`/etc/trojan/trojan -api-addr 127.0.0.1:57721 -api traffic -target-password "${password}"`
if [ $traffic ];then
  echo $traffic
else
  echo "{"success":true,"traffic_total":{"upload_traffic":0,"download_traffic":0},"speed_current":{"upload_speed":0,"download_speed":0}}"
fi
else
  echo "{"success":true,"traffic_total":{"upload_traffic":0,"download_traffic":0},"speed_current":{"upload_speed":0,"download_speed":0}}"
fi
fi 
