include $(TOPDIR)/rules.mk 

PKG_NAME:=luci-app-trojan
PKG_VERSION:=v2.0.2
PKG_MAINTAINER:=frainzy1477

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-trojan
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=2. Trojan
	TITLE:=LuCI app for Trojan
	DEPENDS:=+luci-base +wget +unzip +ip +iptables +bash +ipset +libmbedtls +ca-certificates +iptables-mod-tproxy +pdnsd-alt +curl +dnscrypt-proxy
	PKGARCH:=all
	MAINTAINER:=frainzy1477
endef

define Package/luci-app-trojan/description
	Luci Interface for Trojan
endef

define Build/Prepare
	po2lmo ${CURDIR}/po/zh-cn/trojan.po ${CURDIR}/po/zh-cn/trojan.zh-cn.lmo
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/trojan
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for trojan"
     /etc/init.d/trojan disable
     /etc/init.d/trojan stop
    echo "Removing firewall rule for trojan"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.trojan
		commit firewall
EOF
fi

exit 0
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/dnsmasq.trojan 2>/dev/null
	mv /etc/config/trojan /etc/config/trojan.bak 2>/dev/null
	rm -rf /usr/lib/lua/luci/model/cbi/trojan 2>/dev/null
	rm -rf /usr/lib/lua/luci/view/trojan 2>/dev/null
fi

exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/luci*
	mv /etc/config/trojan.bak /etc/config/trojan 2>/dev/null
	/etc/init.d/trojan disable 2>/dev/null
fi

exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/trojan
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/trojan
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/trojan
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/share/
	$(INSTALL_DIR) $(1)/usr/share/trojan
	$(INSTALL_DIR) $(1)/usr/share/trojan/config/
	$(INSTALL_DIR) $(1)/usr/share/rpcd	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d	
	

	$(INSTALL_BIN) 	./root/etc/init.d/trojan $(1)/etc/init.d/trojan
	$(INSTALL_CONF) ./root/etc/config/trojan $(1)/etc/config/trojan
	$(INSTALL_CONF) ./root/etc/trojan/geosite.dat $(1)/etc/trojan
	$(INSTALL_CONF) ./root/etc/trojan/geoip.dat $(1)/etc/trojan

	$(INSTALL_BIN) ./root/usr/share/rpcd/acl.d/luci-app-trojan.json $(1)/usr/share/rpcd/acl.d
	$(INSTALL_BIN) ./root/usr/share/trojan/luci_version $(1)/usr/share/trojan
	$(INSTALL_BIN) ./root/usr/share/trojan/logstatus_check $(1)/usr/share/trojan
	$(INSTALL_BIN) ./root/usr/share/trojan/*.txt $(1)/usr/share/trojan
	$(INSTALL_BIN) ./root/usr/share/trojan/*.sh $(1)/usr/share/trojan
	$(INSTALL_BIN) ./root/usr/share/trojan/*.csv $(1)/usr/share/trojan

	$(INSTALL_DATA) ./luasrc/trojan.lua $(1)/usr/lib/lua/luci
	$(INSTALL_DATA) ./luasrc/controller/*.lua $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/model/cbi/trojan/*.lua $(1)/usr/lib/lua/luci/model/cbi/trojan
	$(INSTALL_DATA) ./luasrc/view/trojan/* $(1)/usr/lib/lua/luci/view/trojan
	$(INSTALL_DATA) ./po/zh-cn/trojan.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
