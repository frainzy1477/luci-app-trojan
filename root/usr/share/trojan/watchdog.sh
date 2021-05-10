#!/bin/sh /etc/rc.common


count=$(grep -c '' /usr/share/trojan/trojan.txt 2>/dev/null)
enable=$(uci get trojan.@global[0].enable 2>/dev/null)
dns_mode=$(uci get trojan.@settings[0].dns_mode 2>/dev/null)

if [ "${count}" -gt 10000 ];then
 cat /dev/null > /usr/share/trojan/trojan.txt >/dev/null 2>&1 &
fi

if [ "${enable}" -eq 1 ];then
	if [ "$dns_mode" == "pdnsd" ];then
		if ! pidof pdnsd >/dev/null; then
			sh /usr/share/trojan/pdnsd.sh >/dev/null 2>&1 &
		fi
	fi
	if  [ "$dns_mode" == "dnscrypt" ];then
		if ! pidof dnscrypt-proxy >/dev/null; then
			sh /usr/share/trojan/dnscrypt.sh >/dev/null 2>&1 &
		fi
	fi
	if ! pidof trojan-go >/dev/null; then
		/etc/init.d/trojan restart >/dev/null 2>&1 &
	fi
fi

 



