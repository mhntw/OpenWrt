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

# 配置 WiFi：SSID=huawei，密码=abc123abc，SAE-Mixed (WPA2+WPA3)
for radio in $(uci -q show wireless | grep '=wifi-device' | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.${radio}.disabled='0'
    uci set wireless.${radio}.country='CN'
    
    # 5G 信道改为 Auto
    band=$(uci -q get wireless.${radio}.band)
    if [ "$band" = "5g" ]; then
        uci set wireless.${radio}.channel='auto'
    fi
    
    iface="default_${radio}"
    if uci -q get wireless.${iface} >/dev/null 2>&1; then
        uci set wireless.${iface}.ssid='huawei'
        uci set wireless.${iface}.encryption='sae-mixed'
        uci set wireless.${iface}.key='abc123abc'
    fi
done
uci commit wireless

# 开启 Software flow offloading（提升 NAT 性能，IPQ60xx 有 NSS 硬件卸载时可能冗余但无害）
uci set firewall.@defaults[0].flow_offloading='1'
uci commit firewall

# PPPoE 心跳 5秒/次
uci set network.wan.keepalive='5 3'
uci commit network

# TCP Fast Open 客户端+服务端
echo 3 > /proc/sys/net/ipv4/tcp_fastopen
grep -q "tcp_fastopen" /etc/sysctl.conf || echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf

# DHCP 租约 24小时
uci set dhcp.lan.leasetime='24h'
uci commit dhcp

exit 0
