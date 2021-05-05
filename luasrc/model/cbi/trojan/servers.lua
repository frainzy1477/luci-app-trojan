local trojan = "trojan"
local uci = require "luci.model.uci".cursor()
local s, o, m
local fs = require "luci.trojan"

local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local http = luci.http


font_blue = [[<font color="blue">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

b = Map(trojan)
--m.pageaction = false

s = b:section(TypedSection, "server_subscribe", translate("Subscription Update"))
s.anonymous = true

o = s:option(Flag, "auto_update", translate("Auto Update"))
o.description = translate("Auto Update Server Subscription")

o = s:option(ListValue, "auto_update_time", translate("Update time (every day)"))
o:value("1", translate("Every Hour"))
o:value("6", translate("Every 6 Hours"))
o:value("12", translate("Every 12 Hours"))
o:value("24", translate("Every 24 Hours"))
o.description = translate("Daily Server subscription update time")

o = s:option(DynamicList, "subscribe_url", translate("Subscribe URL"))
o.rmempty = true

o = s:option(Button,"update",translate("Update"))
o.inputstyle = "reload"
o.write = function()
    b.uci:commit("trojan")
    luci.sys.call("bash /usr/share/trojan/subscribe.sh >>/usr/share/trojan/trojan.txt 2>&1 &")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan"))
end


m = Map(trojan)
-- servers list --
s = m:section(TypedSection, "servers", translate("Custom Config List"))
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/trojan/server/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end


o = s:option(DummyValue, "name", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "remote_addr", translate("Server Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "remote_port", translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "remote_addr" ,translate("Latency"))
o.template="trojan/ping"
o.width="10%"

o = s:option(DummyValue, "remote_port", translate("Socket Connect"))
o.template="trojan/socket"
o.width="10%"

m:append(Template("trojan/serverlist"))


--local p,x={}
--for q,v in ipairs(fs.glob("/usr/share/trojan/config/*.json")) do
--x=fs.stat(v)
--if x then
--p[q]={}
--p[q].name=fs.basename(v)
--p[q].mtime=os.date("%Y-%m-%d %H:%M:%S",x.mtime)
--p[q].size=tostring(x.size)
--p[q].remove2=0
--p[q].enable=false
--end
--end

--fr=Form("config_list")
--fr.reset=false
--fr.submit=false



--tb=fr:section(Table,p, translate("Upload Config List"))
--nm=tb:option(DummyValue,"name",translate("File Name"))
--mt=tb:option(DummyValue,"mtime",translate("Upload Time"))
--sz=tb:option(DummyValue,"size",translate("Size"))

--function IsYamlFile(p)
--p=p or""
--local p=string.lower(string.sub(p,-5,-1))
--return p==".json"
--end

--btndll = tb:option(Button,"download2",translate("Download")) 
--btndll.template="trojan/other_button"
--btndll.render=function(p,q,x)
--p.inputstyle="remove"
--Button.render(p,q,x)
--end
--btndll.write = function (x,q)
--	local sPath, sFile, fd, block
--	sPath = "/usr/share/trojan/config/"..p[q].name
--	sFile = NXFS.basename(sPath)
--	if fs.isdirectory(sPath) then
--		fd = io.popen('json -C "%s" -cz .' % {sPath}, "r")
--		sFile = sFile .. ".json"
--	else
--		fd = nixio.open(sPath, "r")
--	end
--	if not fd then
--		return
--	end
--	HTTP.header('Content-Disposition', 'attachment; filename="%s"' % {sFile})
--	HTTP.prepare_content("application/octet-stream")
--	while true do
--		block = fd:read(nixio.const.buffersize)
--		if (not block) or (#block ==0) then
--			break
--		else
--			HTTP.write(block)
--		end
--	end
--	fd:close()
--	HTTP.close()
--end


--btnrml=tb:option(Button,"remove2",translate("Remove"))
--btnrml.render=function(p,q,x)
--p.inputstyle="remove"
--Button.render(p,q,x)
--end
--btnrml.write=function(x,q)
--local x=fs.unlink("/usr/share/trojan/config/"..fs.basename(p[q].name))
--if x then table.remove(p,q)end
--return x
--end



--ko = Map(trojan)
--ko.reset = false
--ko.submit = false
--sul =ko:section(TypedSection, "trojan", translate("Upload Config"))
--sul.anonymous = true
--sul.addremove=false
--o = sul:option(FileUpload, "")
--o.description = translate("NB: Only upload file with name .json")
--o.title = translate("  ")
--o.template = "trojan/upload"
--um = sul:option(DummyValue, "", nil)
--um.template = "trojan/dvalue"

--local dir, fd
--dir = "/usr/share/trojan/config/"
--http.setfilehandler(
--
--	function(meta, chunk, eof)
--		if not fd then
--			if not meta then return end
--
--			if	meta and chunk then fd = nixio.open(dir .. meta.file, "w") end
--
--			if not fd then
--				um.value = translate("upload file error.")
--				return
--			end
--		end
--		if chunk and fd then
--			fd:write(chunk)
--		end
--		if eof and fd then
--			fd:close()
--			fd = nil
--			um.value = translate("File saved to") .. ' "/usr/share/trojan/config/'..meta.file..'"'
--		end
--	end
--)

--if luci.http.formvalue("upload") then
--	local f = luci.http.formvalue("ulfile")
--	if #f <= 0 then
--		um.value = translate("No specify upload file.")
--	end
--end

--return b,ko, m , fr
return b, m
