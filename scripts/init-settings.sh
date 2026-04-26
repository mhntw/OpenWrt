#!/bin/bash

# ============================================
# JDCloud AX1800 Pro 固化配置
# 编译时由 GitHub Actions 自动生成密码哈希
# ============================================

# 设置 ROOT 密码 (sha512crypt)
# 密码: passwordTsmjg
# 哈希在编译时由 workflow 动态生成
ROOT_HASH=$(python3 -c "import crypt; print(crypt.crypt('passwordTsmjg', crypt.mksalt(crypt.METHOD_SHA512)))")
sed -i "s|^root:.*|root:${ROOT_HASH}:19500:0:99999:7:::|" /etc/shadow

# 设置 LAN IP
uci set network.lan.ipaddr='192.168.2.1'
uci commit network

# 设置 PPPoE
uci set network.wan.proto='pppoe'
uci set network.wan.username='t532049842071'
uci set network.wan.password='123123'
uci set network.wan.ipv6='1'
uci commit network

# 设置 WiFi 2.4G
uci set wireless.default_radio0.ssid='huawei'
uci set wireless.default_radio0.encryption='psk2+ccmp'
uci set wireless.default_radio0.key='abc123abc'
uci set wireless.radio0.disabled='0'

# 设置 WiFi 5G
uci set wireless.default_radio1.ssid='Huawei5G'
uci set wireless.default_radio1.encryption='psk2+ccmp'
uci set wireless.default_radio1.key='abc123abc'
uci set wireless.radio1.disabled='0'
uci commit wireless

# 设置主机名
uci set system.@system[0].hostname='JDCloud-AX1800'
uci commit system

# 设置默认主题
uci set luci.main.mediaurlbase='/luci-static/argon'
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
