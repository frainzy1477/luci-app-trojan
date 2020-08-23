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
m.pageaction = false
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

o = s:option(Button, "Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputtitle = translate("Save & Apply")
o.inputstyle = "apply"
o.write = function()
m.uci:commit("trojan")
luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan" ,"settings"))

end



x = Map("trojan")
s = x:section(TypedSection, "trojan")
s.anonymous = true
s.addremove=false


o = s:option(FileUpload, "")
o.description =''..font_red..bold_on..translate("Manually upload trojan-go core /etc/trojan/trojan")..bold_off..font_off..' '


o.title = translate("Upload Trogan-go")
o.template = "trojan/upload"
um = s:option(DummyValue, "", nil)
um.template = "trojan/dvalue"

local dir, fd
dir = "/etc/trojan/"


http.setfilehandler(
	function(meta, chunk, eof)
		local fp = HTTP.formvalue("file_type")
		if not fd then
			if not meta then return end
			
			if fp == "trojango" then
			   if meta and chunk then fd = nixio.open(dir .. meta.file, "w") end
			 
			end

			if not fd then
				um.value = translate("upload file error.")
				return
			end
		end
		if chunk and fd then
			fd:write(chunk)
		end
		if eof and fd then
			fd:close()
			fd = nil
			
			if fp == "trojango" then
			    	SYS.exec("chmod 755 /etc/trojan/trojan 2>&1 &")
				SYS.exec("rm -rf /usr/share/trojan/trojango_version 2>/dev/null && /etc/trojan/trojan -version | awk '{print $2}' | sed -n 1P >> /usr/share/trojan/trojango_version 2>/dev/null")
				um.value = translate("File saved to") .. ' "/etc/trojan/'..meta.file..'"' 
			end
			
			
		end
	end
)

if luci.http.formvalue("upload") then
	local f = luci.http.formvalue("ulfile")
	if #f <= 0 then
		um.value = translate("No specify upload file.")
	end
end


o = s:option(ListValue, "download_source", translate("Github User/Repo"))
o.description = translate("Input Github User/Repo of Trogan-go")
o:value("frainzy1477/trojan_go")
o:value("p4gefau1t/trojan-go")
o:value("peter-tank/trojan-go")


local cpu_model=SYS.exec("opkg status libc 2>/dev/null |grep 'Architecture' |awk -F ': ' '{print $2}' 2>/dev/null")
o = s:option(ListValue, "download_core", translate("Select Arch"))
o.description = translate("Architecture")..': '..font_green..bold_on..cpu_model..bold_off..font_off..' '
o:value("linux-386")
o:value("linux-amd64", translate("linux-amd64(x86-64)"))
o:value("linux-armv5")
o:value("linux-armv6")
o:value("linux-armv7")
o:value("linux-armv8")
o:value("linux-mips-hardfloat")
o:value("linux-mips-softfloat")
o:value("linux-mips64")
o:value("linux-mips64le")
o:value("linux-mipsle-softfloat")
o:value("linux-mipsle-hardfloat")


o = s:option(Button, "Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputtitle = translate("Save & Apply")
o.inputstyle = "apply"
o.write = function()
m.uci:commit("trojan")
luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan" ,"settings"))
end

o = s:option(Button,"download")
o.title = translate("Download")
o.template = "trojan/core_check"

return m, x