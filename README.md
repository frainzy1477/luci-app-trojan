<h2 align="center">
  <br>Luci App For Trojan-Go <br>
</h2>
  <p align="center">
	Proxy Client for Openwrt Based On <a href="https://github.com/p4gefau1t/trojan-go" target="_blank">Trojan-GO</a>.
  </p>
  <p align="center">
  <a target="_blank" href="https://github.com/frainzy1477/luci-app-trojan/releases/tag/v2.1.1">
    <img src="https://img.shields.io/badge/Luci%20App%20For%20TrojanGo-v2.1.1-blue.svg"> 	  
  </a>
  <a href="https://github.com/frainzy1477/luci-app-trojan/releases" target="_blank">
        <img src="https://img.shields.io/github/downloads/frainzy1477/luci-app-trojan/total.svg?style=flat-square"/>
   </a>
  </p>

  ![](https://raw.githubusercontent.com/frainzy1477/luci-app-trojan/master/client.png)
  
 ## Install
- Upload ipk file to tmp folder
- cd /tmp
- opkg update
- opkg install luci-app-trojan_v2.1.1_all.ipk  
- opkg install luci-app-trojan_v2.1.1_all.ipk --force-depends

 ## Uninstall
- opkg remove luci-app-trojan 
- opkg remove luci-app-trojan --force-remove

## Features
- Subscription Config
- Create Config
- TProxy UDP
- IP Query
- DNS Forwarding
- Support Trojan(Trojan-Go)
- Ping Custom Proxy Servers
- Access Control
- Rule Manager

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
- wget-ssl
- unzip
- ca-certificates
- iptables-mod-tproxy
- coreutils 
- coreutils-base64 
- luci-compat
- ipt2socks

### trojan-go uri
```
trojan-go://79225126-b565-3e5d-a576-1b8f0425e5fd@abc.xxx.com:443/?sni=abc.xxx.com&type=ws&host=cdn.xxx.com&path=/&encryption=ss%3Baes-128-gcm%3Asspassword#ABC
```
## Credits
* [Trojan-Go](https://github.com/p4gefau1t/trojan-go) by [p4gefau1t](https://github.com/p4gefau1t)

## License  
Luci App For Trojan-Go OpenWrt is released under the GPL v3.0 License - see detailed [LICENSE](https://github.com/frainzy1477/luci-app-trojan/blob/master/LICENSE) .
