local nxfs = require "nixio.fs"
local sys  = require "luci.sys"

m = Map(trojan)
m.pageaction = false
m:append(Template("trojan/status"))


return m

