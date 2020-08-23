#!/bin/sh /etc/rc.common

REAL_LOG="/usr/share/trojan/trojan.txt"
 
count=$(grep -c '' /usr/share/trojan/trojan.txt 2>/dev/null)
enable=$(uci get trojan.@global[0].enable 2>/dev/null)

if [ "${count}" -gt 10000 ];then
 echo "" /usr/share/trojan/trojan.txt >/dev/null 2>&1
fi

if [ "${enable}" -eq 1 ];then

	if ! pidof pdnsd >/dev/null; then
		/usr/sbin/pdnsd -c /var/etc/pdnsd.conf -d >/dev/null 2>&1 &
	fi
	
	if ! pidof trojan >/dev/null; then
		/etc/init.d/trojan restart 2>&1 &
	fi
fi

 



