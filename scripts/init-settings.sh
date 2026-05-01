#!/bin/sh

# ============================================
# JDCloud AX1800 Pro 固化配置
# root 密码: password
# ============================================

# 设置 ROOT 密码 (sha512crypt, 预计算hash)
sed -i 's#^root:.*#root:$6$rounds=656000$OpenWrtsalt$Uq3Rp/GuH/a61IhPMAMmnUk2wGtQ8DswT6fN6J.nXkCjbfAqbyhWO4IeRN/etQXL4.8bdbWPedfGdtp0d.MlI.:19500:0:99999:7:::#' /etc/shadow

# 设置 LAN IP
uci set network.lan.ipaddr='192.168.2.1'
uci commit network

# 设置主机名
uci set system.@system[0].hostname='JDCloud-AX1800'
uci commit system

# 设置默认主题
uci set luci.main.lang='zh_cn'
uci commit luci

# 设置时区
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

# 启用 NTP
uci set system.ntp.enabled='1'
uci add_list system.ntp.server='ntp.tencent.com'
uci add_list system.ntp.server='ntp.aliyun.com'
uci commit system

exit 0
