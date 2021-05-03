#!/bin/bash /etc/rc.common
. /lib/functions.sh

	dns_mode=$(uci get trojan.@settings[0].dns_mode 2>/dev/null)
	dnsstr=$(uci get trojan.@settings[0].tunnel_forward 2>/dev/null)

	usr_dns=`echo "$dnsstr"|sed 's/^\(.*\):\([^:]*\)$/\1/'`
	usr_port=`echo "$dnsstr"|sed 's/^\(.*\):\([^:]*\)$/\2/'`

	[ "$usr_dns" == "127.0.0.1" ] && usr_dns="8.8.4.4" && usr_port="53" && dnsforward=1

	#local usr_dns="$1"
	#local usr_port="$2"

	tcp_dns_list="208.67.222.222, 208.67.220.220"
	[ -z "$usr_dns" ] && usr_dns="8.8.4.4" && usr_port="53"

  [ -d /var/etc ] || mkdir -p /var/etc

   if [ ! -d /var/pdnsd ];then
       mkdir -p /var/pdnsd
       echo -ne "pd13\000\000\000\000" >/var/pdnsd/pdnsd.cache
       chown -R nobody:nogroup /var/pdnsd
   fi

cat > /var/etc/pdnsd.conf <<EOF
global {
	perm_cache=1024;
	cache_dir="/var/pdnsd";
	pid_file = /var/run/pdnsd.pid;
	run_as="nobody";
	server_ip = 127.0.0.1;
	server_port = 5335;
	status_ctl = on;
	query_method = tcp_only;
	min_ttl=1h;
	max_ttl=1w;
	timeout=10;
	neg_domain_pol=on;
	proc_limit=2;
	procq_limit=8;
	par_queries=1;
}
server {
	label= "usrdns";
	ip = $usr_dns;
	port = $usr_port;
	timeout=6;
	uptest=none;
	interval=10m;
	purge_cache=off;
}
server {
	label= "pdnsd";
	ip = $tcp_dns_list;
	port = 5353;
	timeout=6;
	uptest=none;
	interval=10m;
	purge_cache=off;
}
EOF

/usr/sbin/pdnsd -c /var/etc/pdnsd.conf -d
