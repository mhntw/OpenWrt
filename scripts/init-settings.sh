#!/bin/sh
# OpenWrt 默认配置 - 首次启动自动应用
# LAN IP: 192.168.1.1 / 主机名: OpenWrt / WiFi: huawei / abc123abc

# 重置 LAN IP 为默认
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# DNS：使用国内公共 DNS（PPPoE 拒绝运营商 DNS）
uci set network.wan.peerdns='0'
uci set network.wan.dns='223.5.5.5 119.29.29.29'
uci commit network

# dnsmasq 上游 DNS（LAN 客户端使用）
uci set dhcp.@dnsmasq[0].server='223.5.5.5 119.29.29.29'
uci commit dhcp

# 重置主机名为 OpenWrt
uci set system.@system[0].hostname='OpenWrt'
uci commit system

# 强制重置 WiFi 配置（覆盖 overlay 残留）
rm -f /etc/config/wireless
wifi config

# 配置 WiFi：SSID=huawei，密码=abc123abc，WPA2 (中等安全性)
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
        uci set wireless.${iface}.encryption='psk2'
        uci set wireless.${iface}.key='abc123abc'
    fi
done
uci commit wireless

# PPPoE 心跳 5秒/次
uci set network.wan.keepalive='5 3'
uci commit network

# TCP Fast Open 客户端+服务端
echo 3 > /proc/sys/net/ipv4/tcp_fastopen
grep -q "tcp_fastopen" /etc/sysctl.conf || echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf

# DHCP 租约 24小时
uci set dhcp.lan.leasetime='24h'
uci commit dhcp

# 日志轮转 logrotate
opkg install logrotate 2>/dev/null || true
mkdir -p /etc/logrotate.d
cat > /etc/logrotate.d/openwrt << 'LREOF'
/var/log/messages {
    daily
    rotate 5
    size 1M
    compress
    missingok
    notifempty
    create 0640 root root
}
/var/log/dmesg {
    daily
    rotate 3
    size 512k
    compress
    missingok
    notifempty
}
LREOF

exit 0


