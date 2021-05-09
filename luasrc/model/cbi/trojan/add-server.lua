
local m, s, o
local trojan = "trojan"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]
local uuid = luci.sys.exec("cat /proc/sys/kernel/random/uuid")

local server_table = {}

local securitys = {
	"aes-128-gcm",
	"aes-256-gcm",
	"chacha20-poly1305",
	"aead_aes_128_gcm",
	"aead_aes_256_gcm",
	"aead_chacha20_poly1305"
}


m = Map(trojan, translate("Add/Edit Server"))
m.redirect = luci.dispatcher.build_url("admin/services/trojan/servers")
if m.uci:get(trojan, sid) ~= "servers" then
	luci.http.redirect(m.redirect)
	return
end

s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove   = false

o = s:option(DummyValue,"trojan_url","trojan-go URL")
o.rawhtml  = true
o.template = "trojan/url"
o.value =sid

o = s:option(Value, "name", translate("Alias"))
o.default = "Trojan"
o.rmempty = false

o = s:option(Value, "remote_addr", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "remote_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.default = uuid
o.rmempty = false

o = s:option(Value, "sni", translate("SNI"))
o.rmempty = true


-- fingerPrint --
o = s:option(ListValue, "fingerprint", translate("FingerPrint"))
o.default = "firefox"
o:value(" ", translate("None"))
o:value("firefox", translate("firefox"))
o:value("chrome", translate("chrome"))
o:value("ios", translate("ios"))

-- reuse_session --
o = s:option(ListValue, "reuse_session", translate("Reuse Session"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

-- session_ticket --
o = s:option(ListValue, "session_ticket", translate("Session Ticket"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))


-- mux --
o = s:option(ListValue, "mux", translate("Enable Mux"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

o = s:option(Value, "concurrency", translate("Concurrency"))
o.default = 8
o:depends("mux", "true")

o = s:option(Value, "idle_timeout", translate("Idle Timeout"))
o.default = 60
o:depends("mux", "true")


-- tcp fast_open --
o = s:option(ListValue, "fast_open", translate("Fast Open"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

o = s:option(ListValue, "keep_alive", translate("Keep Alive"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))
o:depends("fast_open", "true")

o = s:option(ListValue, "no_delay", translate("No Delay"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))
o:depends("fast_open", "true")

o = s:option(ListValue, "prefer_ipv4", translate("Prefer ipv4"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))
o:depends("fast_open", "true")

-- shadowdocks ---
o = s:option(ListValue, "shadowdocks", translate("Enable Shadowdocks"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

o = s:option(ListValue, "cipher", translate("Encryption Method"))
for _, v in ipairs(securitys) do o:value(v, v:upper()) end
o.rmempty = true
o:depends("shadowdocks", "true")

o = s:option(Value, "shadowdocks_passw", translate("Shadowdocks Password"))
o.password = true
o:depends("shadowdocks", "true")



-- Transport Plugin ---
o = s:option(ListValue, "plugin", translate("Enable Transport Plugin"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

o = s:option(ListValue, "plugin_type", translate("Plugin Type"))
o.default = "plaintext"
o:value("shadowdocks", translate("shadowdocks"))
o:value("plaintext", translate("plaintext"))
o:value("others", translate("others"))
o:depends("plugin", "true")

o = s:option(Value, "plugin_command", translate("Plugin Command"))
o.rmempty = true
o:depends("plugin", "true")

o = s:option(Value, "plugin_arg", translate("Plugin Argument"))
o.rmempty = true
o:depends("plugin", "true")

o = s:option(Value, "plugin_env", translate("Plugin Environment"))
o.rmempty = true
o:depends("plugin", "true")

o = s:option(Value, "plugin_option", translate("Plugin Option"))
o.rmempty = true
o:depends("plugin", "true")


-- websocket--
o = s:option(ListValue, "websocket", translate("Enable Websocket"))
o.default = "false"
o:value("true", translate("True"))
o:value("false", translate("False"))

o = s:option(Value, "path", translate("Websocket Path"))
o.rmempty = true
o:depends("websocket", "true")
o:depends("shadowdocks", "true")

o = s:option(Value, "websocket_host", translate("Websocket Host"))
o.placeholder = translate("example.com")
o.rmempty = true
o:depends("websocket", "true")
o:depends("shadowdocks", "true")


return m
