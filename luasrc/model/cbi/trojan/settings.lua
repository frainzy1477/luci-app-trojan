local uci 		= require("luci.model.uci").cursor()
local fs    	= require("nixio.fs")
local trojan 	= "trojan"
local res_input = "/usr/share/trojan/dnscrypt-resolvers.csv"
local res_dir   = fs.dirname(res_input)
local res_list  = {}
local url       = "https://raw.githubusercontent.com/dyne/dnscrypt-proxy/master/dnscrypt-resolvers.csv"
local ipv4_count=0
local ipv6_count=0

m = Map("trojan")
s = m:section(TypedSection, "settings")
s.anonymous = true
s.addremove=false


if nixio.fs.access("/etc/trojan/china_v4.txt") then
 ipv4_count = luci.sys.exec("cat /etc/trojan/china_v4.txt | wc -l")
end

if nixio.fs.access("/etc/trojan/china_v6.txt") then
 ipv6_count = luci.sys.exec("cat /etc/trojan/china_v6.txt | wc -l")
end


y=s:option(DummyValue,"ipv4_data",translate("China IPv4 Data"))
y.rawhtml  = true
y.template = "trojan/update"
y.value =ipv4_count .. " " .. translate("Records")

y=s:option(DummyValue,"ipv6_data",translate("China IPv6 Data"))
y.rawhtml  = true
y.template = "trojan/update"
y.value =ipv6_count .. " " .. translate("Records")

y = s:option(ListValue, "log_level", translate("Trojan Log Level"))
y:value("0", translate("Output Debug logs(All logs)"))
y:value("1", translate("Output Info log"))
y:value("2", translate("Output Warning logs"))
y:value("3", translate("Output Error logs"))
y:value("4", translate("Output Fatal logs"))
y:value("5", translate("No log output"))
y.default = "1"
y.description = translate("Specify the log level. The higher the level, the less information is output")

y = s:option(ListValue, "access_control", translate("Access Control"))
y:value("0", translate("disabled"))
y:value("1", translate("Proxy Lan List"))
y:value("2", translate("Bypass Lan List"))
y.description = translate("Proxy or Bypass Lan IPs When Trojan-GO is Running")

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



o = s:option(ListValue, "dns_mode", translate("DNS Query Mode"))
--o.widget  = "radio"
o.orientation = "horizontal"
o:value("off", translate("Disabled"))
if nixio.fs.access("/usr/sbin/dnscrypt-proxy") then
o:value("dnscrypt", translate("DNSCrypt"))
end
if nixio.fs.access("/usr/sbin/pdnsd") then
o:value("pdnsd", translate("Pdnsd"))
end
o.description = translate("DNS Query Mode")
o.default = "dnscrypt"
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

if fs.access(res_input) then
	for line in io.lines(res_input) or {} do
		local name,
		location,
		dnssec,
		nolog = line:match("^([^,]+),.-,\".-\",\"*(.-)\"*,.-,[0-9],\"*([yesno]+)\"*,\"*([yesno]+)\"*,.*")
		if name ~= "" and name ~= "Name" then
			if location == "" then
				location = "-"
			end
			if dnssec == "" then
				dnssec = "-"
			end
			if nolog == "" then
				nolog = "-"
			end
			res_list[#res_list + 1] = { name = name, location = location, dnssec = dnssec, nolog = nolog }
		end
	end
end


if fs.access("/lib/libustream-ssl.so") then
	btn1 = s:option(Button, "", translate("Refresh Resolver"),
		translate("Download the current resolver list"))
	btn1.inputtitle = translate("Refresh List")
	btn1.inputstyle = "apply"
	btn1.disabled = false
        btn1:depends("dns_mode", "dnscrypt")
	function btn1.write()
		if not fs.access(res_dir) then
			fs.mkdir(res_dir)
		end
		luci.sys.call("env -i /bin/uclient-fetch --no-check-certificate -O " .. res_input .. " " .. url .. " >/dev/null 2>&1")
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan", "settings"))
	end
else
	btn1 = s:option(Button, "", translate("Refresh Resolver"),
		translate("No SSL support available<br/>")
		.. translate("Please install a libustream-ssl library to download the current resolver list"))
	btn1.inputtitle = translate("-------")
	btn1.inputstyle = "button"
	btn1.disabled = true
        btn1:depends("dns_mode", "dnscrypt")

end


i3 = s:option(ListValue, "resolver", translate("Resolver List"),
	translate("DNS Use To Forward Queries(LOCATION/DNSSEC/NOLOG)"))
i3.datatype = "hostname"
i3.widget = "select"
local i, v
for i, v in ipairs(res_list) do
	if v.name then
		i3:value(v.name, v.name .. " (" .. v.location .. "/" .. v.dnssec .. "/" .. v.nolog .. ")")
	end
end
i3.default = resolver
i3:depends("dns_mode", "dnscrypt")



local apply = luci.http.formvalue("cbi.apply")
if apply then
m.uci:commit("trojan")
if not fs.access("/etc/resolv-crypt.conf") or fs.stat("/etc/resolv-crypt.conf").size == 0 then
luci.sys.call("env -i echo 'options timeout:1' > '/etc/resolv-crypt.conf'")
end
if luci.sys.call("pidof trojan-go >/dev/null") == 0 then
	luci.sys.call("/etc/init.d/trojan restart >/dev/null 2>&1 &")
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan"))
end
end

return m
