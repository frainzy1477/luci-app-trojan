local nxfs = require "nixio.fs"
local sys  = require "luci.sys"
local http = require "luci.http"
local disp = require "luci.dispatcher"
local util = require "luci.util"
local uci = require"luci.model.uci".cursor()
local fs = require "luci.trojan"
local m, s, sec, o
local trojan = "trojan"


font_red = [[<font color="red">]]
font_green = [[<font color="green">]]
font_off = [[</font>]]
bold_on  = [[<b>]]
bold_off = [[</b>]]

m = Map(trojan)
m.pageaction = false


--function IsYamlFile(e)
--   e=e or""
--   local e=string.lower(string.sub(e,-5,-1))
--   return e == ".json"
--end
--function IsYmlFile(e)
--   e=e or""
--  local e=string.lower(string.sub(e,-4,-1))
--   return e == ".json"
--end


--s.anonymous = true
--s = m:section(TypedSection, "trojan")

local server_table = {}
uci:foreach(trojan, "servers", function(s)
	if s.name then
		server_table[s[".name"]] = "[%s] %s:%s" %{s.name, s.remote_addr, s.remote_port}
	elseif s.remote_addr and s.remote__port then
		server_table[s[".name"]] = "%s:%s" %{s.remote_addr, s.remote_port}
	end
end)

local key_table = {}
for key,_ in pairs(server_table) do
    table.insert(key_table,key)
end

table.sort(key_table)


s = m:section(TypedSection, "global")
s.anonymous = true

o = s:option(ListValue, "enable", translate("Client"))
o.default = "0"
o:value("0", translate("Disable"))
o:value("1", translate("Enable"))

--o = s:option(ListValue, "ctype", translate("Type"))
--o.default = "1"
--o:value("1", translate("Server List"))
--o:value("2", translate("Upload Config"))

--o = s:option(ListValue, "global_config", translate("Server"))
--local p,h={}
--for t,f in ipairs(fs.glob("/usr/share/trojan/config/*.json")) do
--	h=fs.stat(f)
--	if h then
--   p[t]={}
--  p[t].name=fs.basename(f)
--    if IsYamlFile(p[t].name) or IsYmlFile(p[t].name) then
--       o:value(""..p[t].name)
--    end
--  end
--end
--o.rmempty = true
--o:depends("ctype", "2")

o = s:option(ListValue, "global_server", translate("Server"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end
o.default = "nil"

o = s:option(ListValue, "run_type", translate("Run Type"))
o.default = "nat"
o:value("nat", translate("TProxy (nat)"))
o:value("client", translate("TProxy+ipt2socks (client)"))

o = s:option(ListValue, "proxy_mode", translate("Mode"))
o:value("global", translate("Global Mode"))
o:value("bypasscn", translate("Bypass CN Mode"))
o:value("chnroute", translate("Oversea Mode"))
o.default = "global"
o:depends("run_type", "nat")

o = s:option(ListValue, "router", translate("Rules"))
o.default = "false"
o:value("false", translate("Disable"))
o:value("true", translate("Enable"))
o:depends("run_type", "client")

o = s:option(Button,"start")
o.title = translate("Operation")
o.inputtitle = translate("START & RESTART & STOP")
o.inputstyle = "reload"
o.write = function()
  m.uci:commit("trojan")
  luci.sys.exec("/etc/init.d/trojan restart >/dev/null 2>&1 &")
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan"))
end


return m

