local m
local trojan = "trojan"

m = Map(trojan)
m.pageaction = false
m:append(Template("trojan/status"))


return m
