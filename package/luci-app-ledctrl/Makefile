include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI - LED Control
LUCI_DEPENDS:=
LUCI_PKGARCH:=all

include ../../luci.mk

define Package/luci-app-ledctrl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/admin
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DATA) ./root/usr/lib/lua/luci/controller/admin/ledctrl.lua $(1)/usr/lib/lua/luci/controller/admin/
	$(INSTALL_DATA) ./root/usr/lib/lua/luci/view/ledctrl.htm $(1)/usr/lib/lua/luci/view/
endef

define Build/Compile
endef

$(eval $(call BuildPackage,luci-app-ledctrl))
