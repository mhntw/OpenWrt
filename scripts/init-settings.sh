#!/bin/sh
# OpenWrt 默认配置 - 首次启动自动应用
# LAN IP: 192.168.1.1 / 主机名: OpenWrt / WiFi: 强制重置

# 重置 LAN IP 为默认
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 重置主机名为默认 OpenWrt
uci set system.@system[0].hostname='OpenWrt'
uci commit system

# 强制重置 WiFi 配置
# 删除旧的 wireless 配置（含 overlay 残留），让系统根据硬件重新生成
rm -f /etc/config/wireless
wifi config

# 确保所有 radio 的 SSID 为 OpenWrt，无密码，启用
for radio in $(uci -q show wireless | grep '=wifi-device' | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.${radio}.disabled='0'
    iface="default_${radio}"
    if uci -q get wireless.${iface} >/dev/null 2>&1; then
        uci set wireless.${iface}.ssid='OpenWrt'
        uci set wireless.${iface}.encryption='none'
    fi
done
uci commit wireless

exit 0
