local HTTP = require "luci.http"
local uci = luci.model.uci.cursor()
local http = luci.http
local trojan = "trojan"

y = Map("trojan")
y.pageaction = false

local t = {
    {Apply}
}

a = y:section(Table, t)

o = a:option(Button, "Apply")
o.inputtitle = translate("Back to Overview")
o.inputstyle = "reset"
o.write = function()
  HTTP.redirect(luci.dispatcher.build_url("admin", "services", "trojan", "client"))
end


x = y:section(TypedSection, "rules", translate("Rule List"))
x.anonymous = true
x.addremove = true
x.sortable = false

x.template = "cbi/tblsection"
x.extedit = luci.dispatcher.build_url("admin/services/trojan/rule/%s")
function x.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(x.extedit % sid)
		return
	end
end

o = x:option(DummyValue, "type", translate("Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = x:option(DummyValue, "format", translate("Format"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end


o = x:option(DummyValue, "name", translate("Rule"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end



local apply = luci.http.formvalue("cbi.apply")
if apply then
	if luci.sys.call("pidof trojan >/dev/null") == 0 then
		luci.sys.call("/etc/init.d/trojan restart >/dev/null 2>&1 &")
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan"))
	else
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "trojan" ,"rules"))
	end
end

return y