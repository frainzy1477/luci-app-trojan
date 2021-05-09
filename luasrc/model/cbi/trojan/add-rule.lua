local m, s, o
local trojan = "trojan"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]


m = Map(trojan, translate("Add/Edit Rule"))
--m.pageaction = false
m.redirect = luci.dispatcher.build_url("admin/services/trojan/rules")
if m.uci:get(trojan, sid) ~= "rules" then
	luci.http.redirect(m.redirect)
	return
end


s = m:section(NamedSection, sid, "rules")
s.anonymous = true
s.addremove   = false


o = s:option(ListValue, "type", translate("Type"))
o.rmempty = false
o.description = translate("Choose Type")
o:value("block", translate("Block"))
o:value("bypass", translate("Bypass"))
o:value("proxy", translate("Proxy"))

o = s:option(ListValue, "format", translate("Format"))
o.rmempty = false
o.description = translate("Choose Format")
o:value("geoip", translate("GEOIP"))
o:value("geosite", translate("GEOSITE"))
o:value("domain", translate("DOMAIN"))
o:value("full", translate("FULL"))
o:value("regexp", translate("REGREX"))
o:value("cidr", translate("CIDR"))


o = s:option(Value, "name", translate("Name"))
o.rmempty = false


return m
