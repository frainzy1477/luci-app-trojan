#!/bin/sh	
	NAME=trojan
	server=`awk '/remote_addr/ {print $0}' /etc/trojan/config.json | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
	udp_allow=$(uci get $NAME.@settings[0].udp 2>/dev/null)				
	if echo $server | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then         
		Server=$server
	else
		Server=`nslookup ${server} | grep 'Address 1' | sed 's/Address 1: //g'`
	fi		
	if [ "$(uci get $NAME.@settings[0].access_control 2>/dev/null)" = "1" ] && [ -n "$(uci get $NAME.@settings[0].proxy_lan_ips 2>/dev/null)" ]; then
		proxy_ips=$(uci get $NAME.@settings[0].proxy_lan_ips 2>/dev/null)
		ipset -! -R <<-EOF
			create proxy_lan hash:net
			$(for ip in $proxy_ips; do echo "add proxy_lan $ip"; done)
		EOF
		
	elif [ "$(uci get $NAME.@settings[0].access_control 2>/dev/null)" = "2" ] && [ -n "$(uci get $NAME.@settings[0].reject_lan_ips 2>/dev/null)" ]; then
		reject_ips=$(uci get $NAME.@settings[0].reject_lan_ips 2>/dev/null)
		ipset -! -R <<-EOF
			create reject_lan hash:net
			$(for ip in $reject_ips; do echo "add reject_lan $ip"; done)
		EOF
		
	fi
	

	if [ -z "$(uci get firewall.$NAME 2>/dev/null)" ] || [ -z "$(uci get ucitrack.@$NAME[-1].init 2>/dev/null)" ]; then
		uci delete ucitrack.@$NAME[-1] >/dev/null 2>&1
		uci add ucitrack $NAME >/dev/null 2>&1
		uci set ucitrack.@$NAME[-1].init=$NAME >/dev/null 2>&1
		uci commit ucitrack >/dev/null 2>&1
		uci delete firewall.$NAME >/dev/null 2>&1
		uci set firewall.$NAME=include >/dev/null 2>&1
		uci set firewall.$NAME.type=script >/dev/null 2>&1
		uci set firewall.$NAME.path=/var/etc/$NAME.include >/dev/null 2>&1
		uci set firewall.$NAME.reload=1 >/dev/null 2>&1
	fi	

	if [ "$(uci get firewall.@defaults[0].forward)" != "ACCEPT" ]; then
		uci set firewall.@defaults[0].forward=ACCEPT >/dev/null 2>&1
		uci commit firewall >/dev/null 2>&1
		/etc/init.d/firewall restart >/dev/null 2>&1
	fi
	
	mkdir -p /var/etc
	cat > "/var/etc/$NAME.include" <<-EOF
		/etc/init.d/$NAME reload >/dev/null 2>&1
	EOF
			
	proxy_mode=$(uci get $NAME.@global[0].proxy_mode 2>/dev/null)
	ip route add local default dev lo table 100
	ip rule add fwmark 1 lookup 100	
	
	ipt6="/sbin/ip6tables"
	
	iptables -t mangle -N TROJAN_GO	

	wan=$(ifconfig | grep 'inet addr' | awk '{print $2}' | cut -d: -f2 2>/dev/null)
	
	ipset create localnetwork hash:net
	ipset add localnetwork 127.0.0.0/8
	ipset add localnetwork 10.0.0.0/8
	ipset add localnetwork 169.254.0.0/16
	ipset add localnetwork 192.168.0.0/16
	ipset add localnetwork 224.0.0.0/4
	ipset add localnetwork 240.0.0.0/4
	ipset add localnetwork 172.16.0.0/12
	ipset add localnetwork $Server
	if [ -n "$wan" ]; then
		for wan_ip4s in $wan; do
			ipset add localnetwork "$wan_ip4s" 2>/dev/null
		done
	fi	
	iptables -t mangle -N TROJAN_GO
	iptables -t mangle -A TROJAN_GO -m set --match-set localnetwork dst -j RETURN
	iptables -t mangle -A TROJAN_GO -m set --match-set reject_lan src -j RETURN
	iptables -t mangle -A TROJAN_GO -m set ! --match-set proxy_lan src -j RETURN				
	if [ "$proxy_mode" == "bypasscn" ];then	
		sh /usr/bin/cnipset >/dev/null 2>&1
		sleep 1
		#iptables -t mangle -A TROJAN_GO -m set  --match-set chinav4 dst -j RETURN
		iptables -t mangle -A TROJAN_GO -p tcp -m set ! --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -m set ! --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			ip6tables -t mangle -N TROJAN_GO
			ip6tables -t mangle -A TROJAN_GO -m set  --match-set chinav6 dst -j RETURN
		fi
	elif [ "$proxy_mode" == "chnroute" ];then
		sh /usr/bin/cnipset ipv4 >/dev/null 2>&1
		sleep 1
		sh /usr/bin/cnipset ipv6 >/dev/null 2>&1	
		#iptables -t mangle -A TROJAN_GO -m set ! --match-set chinav4 dst -j RETURN
		iptables -t mangle -A TROJAN_GO -p tcp -m set --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -m set --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			ip6tables -t mangle -N TROJAN_GO
			ip6tables -t mangle -A TROJAN_GO -m set ! --match-set chinav6 dst -j RETURN
		fi
	else
		iptables -t mangle -A TROJAN_GO -p tcp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
	fi

	iptables -t mangle -A PREROUTING -p tcp -j TROJAN_GO
	iptables -t mangle -A PREROUTING -p udp -j TROJAN_GO
	