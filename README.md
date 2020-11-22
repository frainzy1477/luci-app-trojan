<h2 align="center">
  <br>Luci App For Trojan-Go <br>
</h2>
  <p align="center">
	Proxy Client for Openwrt Based On <a href="https://github.com/p4gefau1t/trojan-go" target="_blank">Trojan-GO</a>.
  </p>
  <p align="center">
  <a target="_blank" href="https://github.com/frainzy1477/luci-app-trojan/releases/tag/v2.0.2">
    <img src="https://img.shields.io/badge/Luci%20App%20For%20TrojanGo-v2.0.2-blue.svg"> 	  
  </a>
  <a href="https://github.com/frainzy1477/luci-app-trojan/releases" target="_blank">
        <img src="https://img.shields.io/github/downloads/frainzy1477/luci-app-trojan/total.svg?style=flat-square"/>
   </a>
  </p>

  
 ## Install
- Upload ipk file to tmp folder
- cd /tmp
- opkg update
- opkg install luci-app-trojan_v2.0.2_all.ipk  
- opkg install luci-app-trojan_v2.0.2_all.ipk --force-depends

 ## Uninstall
- opkg remove luci-app-trojan 
- opkg remove luci-app-trojan --force-remove

## Features
- Config Upload
- Create Config
- TProxy UDP
- IP Query
- DNS Forwarding
- Support Trojan(Trojan-Go)
- Ping Custom Proxy Servers
- Access Control


## Dependency
- curl
- bash
- pdnsd-alt
- dnscrypt-proxy
- libmbedtls
- ipset
- ip
- iptables
- luci
- luci-base
- wget
- unzip
- ca-certificates
- iptables-mod-tproxy

## Credits
* [Trojan-Go](https://github.com/p4gefau1t/trojan-go) by [p4gefau1t](https://github.com/p4gefau1t)

## License  
Luci App For Trojan-Go OpenWrt is released under the GPL v3.0 License - see detailed [LICENSE](https://github.com/frainzy1477/luci-app-trojan/blob/master/LICENSE) .

### trojan-go uri
```
trojan-go://79225126-b565-3e5d-a576-1b8f0425e5fd@uk3.xxx.com:443/?sni=uk3.xxx.com&type=ws&host=uk3.xxx.com&path=/trojan&encryption=ss%3Baes-128-gcm%3AgAtla202#United%20Kingdom%7CB%7CNF%7C*TJ*
```

### Upload Config.json Sample
```
{
    "api": {
        "api_addr": "127.0.0.1",
        "api_port": 57721,
        "enabled": true
    },
    "buffer_size": 32,
    "local_addr": "0.0.0.0",
    "local_port": 51837,
    "log_level": 1,
    "log_file": "/usr/share/trojan/trojan.txt",
    "mux": {
        "concurrency": 8,
        "enabled": true,
        "idle_timeout": 60
    },
    "password": ["your_password"],
    "remote_addr": "your_hostname",
    "remote_port": your_server_port,
    "run_type": "nat",
    "shadowsocks": {
        "enabled": false,
        "method": "",
        "password": ""
    },
    "ssl": {
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "curves": "",
        "fingerprint": "firefox",
        "reuse_session": true,
        "session_ticket": true,
        "sni": "your_hostname",
        "verify": true,
        "verify_hostname": true
    },
    "tcp": {
        "fast_open": true,
        "fast_open_qlen": 20,
        "keep_alive": true,
        "no_delay": false
    },
    "transport_plugin": {
        "enabled": false,
        "type": "",
        "command": "",
        "arg": [],
        "env": [],
        "option": ""
        
    },	
    "websocket": {
        "enabled": false,
        "host": "",
        "path": ""
    }
}
```
