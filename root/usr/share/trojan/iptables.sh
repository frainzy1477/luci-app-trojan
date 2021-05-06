#!/bin/sh
NAME=trojan
TSHARE=/usr/share/$NAME
if [ "$1" = "start" ];then	
	server=`awk '/remote_addr/ {print $0}' /etc/trojan/config.json | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
	#udp_allow=$(uci get $NAME.@settings[0].udp 2>/dev/null)
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
	ip route add local default dev lo table 100
	ip rule add fwmark 1 lookup 100
	ipt6="/sbin/ip6tables"
	iptables -t mangle -N TROJAN_GO
	iptables -t mangle -F TROJAN_GO	
	iptables -t mangle -A TROJAN_GO -m set --match-set localnetwork dst -j RETURN
	iptables -t mangle -A TROJAN_GO -m set --match-set reject_lan src -j RETURN
	iptables -t mangle -A TROJAN_GO -m set ! --match-set proxy_lan src -j RETURN
	if [ $ipt6 ];then
		ip6tables -t mangle -N TROJAN_GO
		ip6tables -t mangle -F TROJAN_GO
	fi	
	if [ "$proxy_mode" == "bypasscn" ];then
		sh $TSHARE/cnipset.sh ipv4 >/dev/null 2>&1
		sleep 1
		iptables -t mangle -A TROJAN_GO -p tcp -m set ! --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -m set ! --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			sh $TSHARE/cnipset.sh ipv6 >/dev/null 2>&1	
			ip6tables -t mangle -A TROJAN_GO -p tcp -m set  --match-set chinav6 dst -j RETURN
			ip6tables -t mangle -A TROJAN_GO -p udp -m set  --match-set chinav6 dst -j RETURN
		fi
	elif [ "$proxy_mode" == "chnroute" ];then
		sh $TSHARE/cnipset.sh ipv4 >/dev/null 2>&1
		iptables -t mangle -A TROJAN_GO -p tcp -m set --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -m set --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			sh $TSHARE/cnipset.sh ipv6 >/dev/null 2>&1	
			ip6tables -t mangle -A TROJAN_GO -p tcp -m set ! --match-set chinav6 dst -j RETURN
			ip6tables -t mangle -A TROJAN_GO -p udp -m set ! --match-set chinav6 dst -j RETURN
		fi
	else
		iptables -t mangle -A TROJAN_GO -p tcp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01		
	fi
	iptables -t mangle -A PREROUTING -p tcp -j TROJAN_GO
	iptables -t mangle -A PREROUTING -p udp -j TROJAN_GO
	if [ $ipt6 ];then
		ip6tables -t mangle -A PREROUTING -p tcp -j TROJAN_GO
		ip6tables -t mangle -A PREROUTING -p udp -j TROJAN_GO
	fi
fi


if [ "$1" = "stop" ];then
	rm -rf /var/etc/$NAME.include 2>/dev/null
	ip route del local default dev lo table 100
	ip rule del fwmark 1 lookup 100
	iptables -t mangle -F TROJAN_GO 2>/dev/null
	iptables -t mangle -X TROJAN_GO 2>/dev/null
	ip6tables -t mangle -F TROJAN_GO 2>/dev/null
	ip6tables -t mangle -X TROJAN_GO 2>/dev/null
	ipset -! flush proxy_lan >/dev/null 2>&1
	ipset -! flush reject_lan >/dev/null 2>&1
	ipset -! flush gfw >/dev/null 2>&1
	ipset -! flush chinav4 >/dev/null 2>&1
	ipset -! flush chinav6 >/dev/null 2>&1
	ipset destroy reject_lan >/dev/null 2>&1
	ipset destroy gfw >/dev/null 2>&1
	ipset destroy proxy_lan >/dev/null 2>&1
	ipset destroy chinav4 >/dev/null 2>&1
	ipset destroy chinav6 >/dev/null 2>&1
	ipset destroy localnetwork >/dev/null 2>&1
	nat=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/tcp dpt:53/=' | sort -r)
	for natx in $nat; do
			iptables -t nat -D PREROUTING $natx >/dev/null 2>&1
	done
	mag=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/TROJAN_GO/=' | sort -r)
	for nat_indexv in $mag; do
		iptables -t mangle -D PREROUTING $nat_indexv >/dev/null 2>&1
	done
	mag6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/TROJAN_GO/=' | sort -r)
	for nat_index6 in $mag6; do
		ip6tables -t mangle -D PREROUTING $nat_index6 >/dev/null 2>&1
	done
	proxy_lan=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/proxy_lan src/=' | sort -r)
	for natx in $proxy_lan; do
		iptables -t mangle -D PREROUTING $natx >/dev/null 2>&1
	done
	reject_lan=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/reject_lan src/=' | sort -r)
	for natx in $reject_lan; do
		iptables -t mangle -D PREROUTING $natx >/dev/null 2>&1
	done
	chinav4_lan=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/chinav4/=' | sort -r)
	for natv4 in $chinav4_lan; do
		iptables -t mangle -D PREROUTING $natv4 >/dev/null 2>&1
	done
	chinav6_lan=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/chinav6/=' | sort -r)
	for natv6 in $chinav6_lan; do
		iptables -t mangle -D PREROUTING $natv6 >/dev/null 2>&1
	done	
	pre=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/localnetwork/=' | sort -r)
	for prer in $pre; do
		iptables -t mangle -D PREROUTING $prer 2>/dev/null
	done
	iptables -t nat -I PREROUTING -p tcp --dport 53 -j ACCEPT	
	proxy_lan6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/proxy_lan src/=' | sort -r)
	for natx in $proxy_lan6; do
		ip6tables -t mangle -D PREROUTING $natx >/dev/null 2>&1
	done
	reject_lan6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/reject_lan src/=' | sort -r)
	for natx in $reject_lan6; do
		ip6tables -t mangle -D PREROUTING $natx >/dev/null 2>&1
	done
	chinav4_lan6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/chinav4/=' | sort -r)
	for natv4 in $chinav4_lan6; do
		ip6tables -t mangle -D PREROUTING $natv4 >/dev/null 2>&1
	done
	chinav6_lan6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/chinav6/=' | sort -r)
	for natv6 in $chinav6_lan6; do
		ip6tables -t mangle -D PREROUTING $natv6 >/dev/null 2>&1
	done	
	pre6=$(ip6tables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/localnetwork/=' | sort -r)
	for prer in $pre6; do
		ip6tables -t mangle -D PREROUTING $prer 2>/dev/null
	done	
fi
