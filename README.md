<h2 align="center">
  <br>Luci App For Trojan-Go <br>
</h2>

  <p align="center">
  <a target="_blank" href="https://github.com/frainzy1477/luci-app-trojan/releases/tag/v1.0.0">
    <img src="https://img.shields.io/badge/Luci%20App%20For%20TrojanGo-v1.0.0-blue.svg"> 	  
  </a>
  <a href="https://github.com/frainzy1477/luci-app-trojan/releases" target="_blank">
        <img src="https://img.shields.io/github/downloads/frainzy1477/luci-app-trojan/total.svg?style=flat-square"/>
   </a>
  </p>

  
 ## Install
- Upload ipk file to tmp folder
- cd /tmp
- opkg update
- opkg install luci-app-trojan_v1.0.0_all.ipk  
- opkg install luci-app-trojan_v1.0.0_all.ipk --force-depends

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

- bash
- pdnsd-alt
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
* Trojan-Go [Trojan-Go](https://github.com/p4gefau1t/trojan-go) by [p4gefau1t](https://github.com/p4gefau1t)

## License  
Luci App For Trojan-Go OpenWrt is released under the GPL v3.0 License - see detailed [LICENSE](https://github.com/frainzy1477/luci-app-trojan/blob/master/LICENSE) .


## Upload Config Sample
```
{

    "buffer_size": 32,
    "forward_proxy": {
        "enabled": false,
        "proxy_addr": "127.0.0.1",
        "proxy_port": 1086
    },	
    "local_addr": "0.0.0.0",
    "local_port": 51837,
    "log_level": 1,
    "mux": {
        "concurrency": 8,
        "enabled": true,
        "idle_timeout": 60
    },
    "password": [
        "password"
    ],
    "remote_addr": "",
    "remote_port": 443,
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
        "sni": "",
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
        "hostname": "",
        "path": ""
    },	
    "router":{
        "enabled": true,
        "bypass": [
                    "geoip:cn",
                    "geoip:private",
                    "geosite:cn",
                    "geosite:geolocation-cn"
        ],
        "block": [
                    "geosite:category-ads"
        ],
        "proxy": [
                    "geosite:geolocation-!cn"
        ],
        "default_policy": "proxy",
        "domain_strategy": "as_is"
    }
}
```