#!/bin/sh
if [ -f /etc/trojan/china_v4.txt ];then
		ipset -N chinav4 hash:net 2>/dev/null
		awk '!/^$/&&!/^#/{printf("add china_v4 %s'" "'\n",$0)}' /etc/trojan/china_v4.txt > /tmp/china.ipset
		ipset -F chinav4 2>/dev/null
		ipset -R < /tmp/china.ipset 2>/dev/null
fi
rm -f /tmp/china*.ipset 2>/dev/null