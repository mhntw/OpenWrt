#!/bin/sh
# OpenWrt 默认配置 - 首次启动自动应用
# LAN IP: 192.168.1.1 / 主机名: OpenWrt / WiFi: 默认

# 重置 LAN IP 为默认
uci set network.lan.ipaddr='192.168.1.1'
uci commit network

# 重置主机名为默认 OpenWrt
uci set system.@system[0].hostname='OpenWrt'
uci commit system

exit 0
