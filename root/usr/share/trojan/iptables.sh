#!/bin/sh	

	NAME=trojan
	$BIN_DIR=/usr/share/$NAME
	$CONFIG_FILE=/etc/$NAME/config.json	
	
	server=`awk '/remote_addr/ {print $0}' $CONFIG_FILE | sed 's/\,//' | sed 's/\"//g' | grep : | awk -F ': ' '{print $2}'`
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
	mkdir -p /var/etc
	cat > "/var/etc/$NAME.include" <<-EOF
		/etc/init.d/$NAME reload >/dev/null 2>&1
	EOF
		
		
	proxy_mode=$(uci get $NAME.@global[0].proxy_mode 2>/dev/null)
	ip route add local default dev lo table 100
	ip rule add fwmark 1 lookup 100	
	
	ipt6="/sbin/ip6tables"
	
	iptables -t mangle -N TROJAN_GO	
	iptables -t mangle -A TROJAN_GO -d $Server -j RETURN
	iptables -t mangle -A TROJAN_GO -d 0.0.0.0/8 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 10.0.0.0/8 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 127.0.0.0/8 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 169.254.0.0/16 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 172.16.0.0/12 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 192.168.0.0/16 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 224.0.0.0/4 -j RETURN
	iptables -t mangle -A TROJAN_GO -d 240.0.0.0/4 -j RETURN
	iptables -t mangle -A TROJAN_GO -m set --match-set reject_lan src -j RETURN
	iptables -t mangle -A TROJAN_GO -m set ! --match-set proxy_lan src -j RETURN				
	if [ "$proxy_mode" == "bypasscn" ];then	
		sh /usr/bin/cnipset ipv4 >/dev/null 2>&1
		sleep 1
		sh /usr/bin/cnipset ipv6 >/dev/null 2>&1
		iptables -t mangle -A TROJAN_GO -m set ! --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			ip6tables -t mangle -N TROJAN_GO
			ip6tables -t mangle -A TROJAN_GO -m set  --match-set chinav6 dst -j RETURN
		fi
		iptables -t mangle -A PREROUTING -j TROJAN_GO
	elif [ "$proxy_mode" == "chnroute" ];then
		sh /usr/bin/cnipset ipv4 >/dev/null 2>&1
		sleep 1
		sh /usr/bin/cnipset ipv6 >/dev/null 2>&1	
		iptables -t mangle -A TROJAN_GO -m set  --match-set chinav4 dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		if [ $ipt6 ];then
			ip6tables -t mangle -N TROJAN_GO
			ip6tables -t mangle -A TROJAN_GO -m set ! --match-set chinav6 dst -j RETURN
		fi
		iptables -t mangle -A PREROUTING -j TROJAN_GO
	elif [ "$proxy_mode" == "gfw" ];then
		cat > /tmp/dnsmasq.d/$NAME.conf <<EOF
			conf-dir=/var/etc/dnsmasq.$NAME
EOF
		mkdir -p /var/etc/dnsmasq.$NAME
		ln -s /etc/$NAME/gfw.list /var/etc/dnsmasq.$NAME/
		ln -s /etc/$NAME/ads.conf /var/etc/dnsmasq.$NAME/
		ipset -N gfw hash:net 2>/dev/null
		iptables -t mangle -A TROJAN_GO -m set --match-set gfw dst -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A PREROUTING -j TROJAN_GO	
	elif [ "$proxy_mode" == "global" ];then
		iptables -t mangle -A TROJAN_GO -p tcp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
		iptables -t mangle -A TROJAN_GO -p udp -j TPROXY --on-port 51837 --tproxy-mark 0x01/0x01
	    iptables -t mangle -A PREROUTING -p tcp -j TROJAN_GO
	    iptables -t mangle -A PREROUTING -p udp -j TROJAN_GO
	fi
	