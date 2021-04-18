module("luci.controller.trojan", package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
local uci=require"luci.model.uci".cursor()
local trojan = require "luci.trojan"

function index()

	if not nixio.fs.access("/etc/config/trojan") then
		return
	end

	local page = entry({"admin", "services", "trojan"},alias("admin", "services", "trojan", "overview"), _("TrojanGO"), 2)
	page.dependent = true
	page.acl_depends = {"luci-app-trojan"}
	
    entry({"admin", "services", "trojan", "overview"},cbi("trojan/status"),_("Overview"), 10).leaf = true
	entry({"admin", "services", "trojan", "client"},cbi("trojan/client"),_("Client"), 20).leaf = true
	--entry({"admin", "services", "trojan", "rules"},cbi("trojan/rules"), nil).leaf = true
	--entry({"admin", "services", "trojan", "rule"},cbi("trojan/add-rule"), nil).leaf = true
	entry({"admin", "services", "trojan", "servers" },cbi("trojan/servers"),_("Servers"), 30).leaf = true
	entry({"admin", "services", "trojan", "server"},cbi("trojan/add-server"), nil).leaf = true
	entry({"admin", "services", "trojan", "settings"},cbi("trojan/settings"),_("Settings"), 50).leaf = true
	entry({"admin", "services", "trojan", "update"},cbi("trojan/update"),_("Update"), 60).leaf = true
	entry({"admin", "services", "trojan", "logs"},cbi("trojan/logs"),_("Logs"), 70).leaf = true
	
	entry({"admin", "services", "trojan", "ping"}, call("act_ping")).leaf=true
	entry({"admin", "services", "trojan", "status"},call("action_status")).leaf=true
	entry({"admin", "services", "trojan", "run"},call("action_run")).leaf=true
	entry({"admin", "services", "trojan", "check_update_log"}, call("check_update_log")).leaf=true
	entry({"admin", "services", "trojan", "do_update"}, call("do_update")).leaf=true
	entry({"admin", "services", "trojan", "corelog"},call("down_check")).leaf=true
	entry({"admin", "services", "trojan", "logstatus"},call("logstatus_check")).leaf=true
	entry({"admin", "services", "trojan", "readlog"},call("action_read")).leaf=true
	entry({'admin', 'services', "trojan", 'ip'}, call('checkip')).leaf=true
	
end


local function trojan_running()
	if nixio.fs.access("/usr/share/trojan/1") then
		return "1"
	else
		return "0"
	end	
end

local function dnscrypt_proxy()
 return luci.sys.call("pidof dnscrypt-proxy >/dev/null") == 0                   
end	

local function pdnsd_running()
 return luci.sys.call("pidof pdnsd >/dev/null") == 0                   
end	

local function trojan_traffic()
	return luci.sys.exec("sh /usr/share/trojan/traffic.sh")
end

local function trojan_core()
	if nixio.fs.access("/etc/trojan/trojan") then
		local core=luci.sys.exec("/etc/trojan/trojan -version | awk '{print $2}' | sed -n 1P")		
		if core ~= "" then
			return luci.sys.exec("/etc/trojan/trojan -version | awk '{print $2}' | sed -n 1P")
		else
			return luci.sys.exec("sed -n 1p /usr/share/trojan/core_version")
		end
	else
		return "0"
	end
end

local function check_core_new()
	return luci.sys.exec("sh /usr/share/trojan/trojan_core_new.sh")
end


local function trojan_core_new()
	return luci.sys.exec("sed -n 1p /usr/share/trojan/trojan_core_new")
end

local function current_version()
	return luci.sys.exec("sed -n 1p /usr/share/trojan/luci_version")
end

local function new_version()
	return luci.sys.exec("sed -n 1p /usr/share/trojan/new_luci_version")
end

local function check_version()
	return luci.sys.exec("sh /usr/share/trojan/check_luci_version.sh")
end

local function downcheck()
	if nixio.fs.access("/var/run/core_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/core_update") then
		return "1"
	elseif nixio.fs.access("/usr/share/trojan/core_down_complete") then
		return "2"
	end
end


function down_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 downcheck = downcheck();
	})
end

function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		trojan_core = trojan_core(),
		trojan_core_new = trojan_core_new(),
		check_core_new = check_core_new(),
		pdnsd = pdnsd_running(),
		dnscrypt = dnscrypt_proxy(),
		check_version = check_version(),
		current_version = current_version(),
		new_version = new_version(),
		traffic = trojan_traffic(),		
		client = trojan_running()
	})
end

function action_run()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		pdnsd = pdnsd_running(),
		dnscrypt = dnscrypt_proxy(),	
		client = trojan_running()
	})
end

function act_ping()
	local e={}
	e.index=luci.http.formvalue("index")
	e.ping=luci.sys.exec("ping -c 1 -W 1 -w 5 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'"%luci.http.formvalue("domain"))
	local domain = luci.http.formvalue("domain")
	local port = luci.http.formvalue("port")
	local socket = nixio.socket("inet", "stream")
	socket:setopt("socket", "rcvtimeo", 3)
	socket:setopt("socket", "sndtimeo", 3)
	e.socket = socket:connect(domain, port)
	socket:close()	
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function do_update()
	fs.writefile("/var/run/trojanlog","0")
	luci.sys.exec("(rm /var/run/core_update_error ;  touch /var/run/core_update ; sh /usr/share/trojan/core_download.sh >/tmp/trojan_update.txt 2>&1  || touch /var/run/core_update_error ;rm /var/run/core_update) &")
end

function check_update_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp=tonumber(fs.readfile("/var/run/trojanlog")) or 0
	local f=io.open("/tmp/trojan_update.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	fs.writefile("/var/run/trojanlog",tostring(fdp))
	f:close()
if fs.access("/var/run/core_update") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end


function logstatus_check()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp=tonumber(fs.readfile("/usr/share/trojan/logstatus_check")) or 0
	local f=io.open("/usr/share/trojan/trojan.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	fs.writefile("/usr/share/trojan/logstatus_check",tostring(fdp))
	f:close()
if fs.access("/var/run/logstatus") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end


local function readlog()
	return luci.sys.exec("sed -n '$p' /usr/share/trojan/readlog.txt 2>/dev/null")
end


function action_read()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	readlog = readlog();
	})
end


function check(host, port)
    local nixio = require "nixio"
    local socket = nixio.socket("inet", "stream")
    socket:setopt("socket", "rcvtimeo", 2)
    socket:setopt("socket", "sndtimeo", 2)
    local ret = socket:connect(host, port)
    socket:close()
    return ret
end


function checkip()
    local e = {}
    local port = 80
    e.baidu = check('www.baidu.com', port)
    e.taobao = check('www.taobao.com', port)
    e.google = check('www.google.com', port)
    e.youtube = check('www.youtube.com', port)
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end