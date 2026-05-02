#!/bin/sh
# OpenWrt 默认配置 - 首次启动自动应用
# LAN IP: 192.168.1.1 / 主机名: OpenWrt / WiFi: huawei / abc123abc

# 重置 LAN IP 为默认
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 重置主机名为 OpenWrt
uci set system.@system[0].hostname='OpenWrt'
uci commit system

# 强制重置 WiFi 配置（覆盖 overlay 残留）
rm -f /etc/config/wireless
wifi config

# 配置 WiFi：SSID=huawei，密码=abc123abc，WPA2
for radio in $(uci -q show wireless | grep '=wifi-device' | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.${radio}.disabled='0'
    # 默认 channel 适配（2.4G=6, 5G=36）
    iface="default_${radio}"
    if uci -q get wireless.${iface} >/dev/null 2>&1; then
        uci set wireless.${iface}.ssid='huawei'
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='abc123abc'
    fi
done
uci commit wireless

exit 0
