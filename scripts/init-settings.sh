#!/bin/sh

# ============================================
# JDCloud AX1800 Pro 固化配置
# LAN IP: 192.168.2.1
# WiFi: Huawei5G / abc123abc
# ============================================

# 设置 LAN IP
uci set network.lan.ipaddr='192.168.2.1'
uci commit network

# 设置 WiFi
uci set wireless.@wifi-iface[0].ssid='Huawei5G'
uci set wireless.@wifi-iface[0].key='abc123abc'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.radio0.disabled='0'
uci commit wireless

exit 0
