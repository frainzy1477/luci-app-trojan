#!/bin/sh
if [ "$1" == "ipv6" ];then
	if [ -f /etc/trojan/china_v6.txt ];then
		ipset -N chinav6 hash:net family inet6 2>/dev/null
		awk '!/^$/&&!/^#/{printf("add china_v6 %s'" "'\n",$0)}' /etc/trojan/china_v6.txt > /tmp/china_v6.ipset
		ipset -F chinav6 2>/dev/null
		ipset -R < /tmp/china_v6.ipset 2>/dev/null
	fi
fi
if [ "$1" == "ipv4" ];then
	if [ -f /etc/trojan/china_v4.txt ];then
		ipset -N chinav4 hash:net 2>/dev/null
		awk '!/^$/&&!/^#/{printf("add china_v4 %s'" "'\n",$0)}' /etc/trojan/china_v4.txt > /tmp/china.ipset
		ipset -F chinav4 2>/dev/null
		ipset -R < /tmp/china.ipset 2>/dev/null
	fi
fi
rm -f /tmp/china*.ipset 2>/dev/null