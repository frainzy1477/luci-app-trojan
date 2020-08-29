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

x = Map("trojan")
s = x:section(TypedSection, "trojan")
s.anonymous = true
s.addremove=false

o = s:option(DummyValue, "_status", translate("Trojan-Go"))
o.value = "<span id=\"_trojan\" style=\"line-height: 2.1em;\">%s</span> <span id=\"_trojan_new\" style=\"line-height: 2.1em;\"></span>" %{translate("【  】")}
o.rawhtml = true

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


o = s:option(ListValue, "download_source", translate("Download Trogan-go"))
o.description = translate("Download Trogan-go")
o:value("frainzy1477/trojan_go")


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


o = s:option(Button,"download")
o.title = translate("Download")
o.template = "trojan/core_check"

return x