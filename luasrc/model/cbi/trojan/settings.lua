local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci = require("luci.model.uci").cursor()
local trojan = "trojan"
local http = luci.http

font_red = [[<font color="red">]]
font_green = [[<font color="green">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

m = Map("trojan")
s = m:section(TypedSection, "trojan")
s.anonymous = true
s.addremove=false


y = s:option(ListValue, "dnscache", translate("DNS Cache"))
y:value("0", translate("disabled"))
y:value("1", translate("enabled"))
y.description = translate("Set to enable or disable dns cache")


---- DNS Forward Mode
o = s:option(ListValue, "dns_mode", translate("DNS Forwarder"))
--o.widget  = "radio"
o.orientation = "horizontal"
o:value("pdnsd", translate("Use Pdnsd tcp query and cache"))
o.default = "pdnsd"
o.rmempty = false

o = s:option(ListValue, "tunnel_forward", translate("DNS Servers"), luci.util.pcdata(translate("DNS Use To Forward Queries")))
o:value("8.8.4.4:53", translate("Google Public DNS (8.8.4.4)"))
o:value("8.8.8.8:53", translate("Google Public DNS (8.8.8.8)"))
o:value("208.67.222.222:53", translate("OpenDNS (208.67.222.222)"))
o:value("208.67.220.220:53", translate("OpenDNS (208.67.220.220)"))
o:value("1.1.1.1:53", translate("Cloudflare DNS (1.1.1.1)"))
o:value("114.114.114.114:53", translate("Oversea Mode DNS-1 (114.114.114.114)"))
o:value("114.114.115.115:53", translate("Oversea Mode DNS-2 (114.114.115.115)"))
o:depends("dns_mode", "pdnsd")


y = s:option(ListValue, "access_control", translate("Access Control"))
y:value("0", translate("disabled"))
y:value("1", translate("Whitelist IPs"))
y:value("2", translate("Blacklist Ips"))
y.description = translate("Whitelist or Blacklist IPs to use Trojan")

o = s:option(DynamicList, "proxy_lan_ips", translate("Proxy Lan List"))
o.datatype = "ipaddr"
o.description = translate("Only selected IPs will be proxied")
luci.ip.neighbors({ family = 4 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
o:depends("access_control", 1)


o = s:option(DynamicList, "reject_lan_ips", translate("Bypass Lan List"))
o.datatype = "ipaddr"
o.description = translate("Selected IPs will not be proxied")
luci.ip.neighbors({ family = 4 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
o:depends("access_control", 2)

local apply = luci.http.formvalue("cbi.apply")
if apply then
if luci.sys.call("pidof trojan >/dev/null") == 0 then
	luci.sys.call("/etc/init.d/trojan restart >/dev/null 2>&1 &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan"))
end
end

return m