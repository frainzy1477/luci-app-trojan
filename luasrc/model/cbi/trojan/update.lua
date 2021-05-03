local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci = require("luci.model.uci").cursor()
local trojan = "trojan"
local http = luci.http

local version = luci.sys.exec("/usr/bin/trojan-go -version | awk '{print $2}' | sed -n 1P")

font_red = [[<font color="red">]]
font_green = [[<font color="green">]]
font_off = [[</font>]]
bold_on  = [[<b>]]
bold_off = [[</b>]]

x = Map("trojan")
s = x:section(TypedSection, "trojan")
s.anonymous = true
s.addremove=false

o = s:option(DummyValue, "_status", translate("Trojan-Go"))
o.value = ''..font_green..bold_on..'【'..version..' 】'..bold_off..font_off.."<span id=\"_trojan_new\" style=\"line-height: 2.1em;\"></span>"
o.rawhtml = true

o = s:option(FileUpload, "")
o.description =''..font_red..bold_on..translate("Manually upload trojan-go core /usr/bin/trojan-go")..bold_off..font_off..' '
.."<br />"
..translatef("<a href=\"%s\" target=\"_blank\">"..translate("Download Trojan-go Core from Here").."</a>", translate("https://github.com/frainzy1477/trojan-go/releases/"))


o.title = translate("Upload")
o.template = "trojan/upload"
um = s:option(DummyValue, "", nil)
um.template = "trojan/dvalue"

local dir, fd
dir = "/usr/bin/"


http.setfilehandler(
	function(meta, chunk, eof)

		if not fd then
			if not meta then return end
			if luci.sys.call("pidof trojan-go >/dev/null") == 0 then
				luci.sys.exec("/etc/init.d/trojan stop >/dev/null 2>&1 &")
			end			
			if meta and chunk then fd = nixio.open(dir .. meta.file, "w") end
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
			    	SYS.exec("chmod 755 /usr/bin/trojan-go 2>&1 &")
				SYS.exec("rm -rf /usr/share/trojan/trojango_version 2>/dev/null && /usr/bin/trojan-go -version | awk '{print $2}' | sed -n 1P >> /usr/share/trojan/trojango_version 2>/dev/null")
				um.value = translate("File saved to") .. ' "/usr/bin/'..meta.file..'"'
				luci.sys.exec("/etc/init.d/trojan start >/dev/null 2>&1 &")
		end
	end
)

if luci.http.formvalue("upload") then
	local f = luci.http.formvalue("ulfile")
	if #f <= 0 then
		um.value = translate("No specify upload file.")
	end
end


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
