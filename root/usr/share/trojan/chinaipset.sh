echo "create china hash:net family inet hashsize 1024 maxelem 65536" > /tmp/china.ipset
awk '!/^$/&&!/^#/{printf("add china_v4 %s'" "'\n",$0)}' /usr/share/trojan/china_v4.txt >> /tmp/china_v4.ipset
ipset -! flush china_v4
ipset -! restore < /tmp/china_v4.ipset 2>/dev/null
 
ipset -N china_v6 hash:net family inet6 2>/dev/null
awk '!/^$/&&!/^#/{printf("add china_v6 %s'" "'\n",$0)}' /usr/share/trojan/china_v6.txt > /tmp/china_v6.ipset
ipset -F china_v6 2>/dev/null
ipset -R < /tmp/china_v6.ipset 2>/dev/null

rm -f /tmp/china_v4.ipset /tmp/china_v6.ipset



