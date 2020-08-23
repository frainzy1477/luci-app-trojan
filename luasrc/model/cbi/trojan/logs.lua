local NXFS = require "nixio.fs"
local HTTP = require "luci.http"

local uci = require("luci.model.uci").cursor()
local fs = require "luci.trojan"
local http = luci.http

m = Map("trojan")
s = m:section(TypedSection, "trojan")
m.pageaction = false
s.anonymous = true
s.addremove=false

log = s:option(TextValue, "clog")
log.template = "trojan/logs"

o = s:option(Button, "Download") 
o.inputtitle = translate("Download logs")
o.inputstyle = "apply"
o.write = function ()
	local sPath, sFile, fd, block
	sPath = "/usr/share/trojan/trojan.txt"
	sFile = NXFS.basename(sPath)
	if fs.isdirectory(sPath) then
		fd = io.popen('txt -C "%s" -cz .' % {sPath}, "r")
		sFile = sFile .. ".txt"
	else
		fd = nixio.open(sPath, "r")
	end
	if not fd then
		return
	end
	HTTP.header('Content-Disposition', 'attachment; filename="%s"' % {sFile})
	HTTP.prepare_content("application/octet-stream")
	while true do
		block = fd:read(nixio.const.buffersize)
		if (not block) or (#block ==0) then
			break
		else
			HTTP.write(block)
		end
	end
	fd:close()
	HTTP.close()
end

return m
