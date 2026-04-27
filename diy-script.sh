#!/bin/bash
# OpenWrt DIY script - 在 feeds install 之后执行
# 功能：应用补丁（显示 SoC 状态到 LuCI）

set -e

echo "==> 开始执行 DIY 脚本..."

# 1. 应用 patches/（显示 SoC 状态到 LuCI）
if [ -d "$GITHUB_WORKSPACE/patchs" ] && [ "$(ls -A $GITHUB_WORKSPACE/patchs/*.patch 2>/dev/null)" ]; then
    echo "==> 应用补丁..."
    # 补丁路径是 modules/luci-base/...，需要在 feeds/luci/ 目录下应用
    if [ -d "feeds/luci" ]; then
        cd feeds/luci
        find "$GITHUB_WORKSPACE/patchs" -name "*.patch" | sort | while read -r patch; do
            echo "应用: $(basename "$patch")"
            patch -p1 -N < "$patch" 2>/dev/null || echo "补丁 $(basename "$patch") 已应用或跳过"
        done
        cd ../..
    else
        echo "⚠️ feeds/luci 目录不存在，跳过补丁应用"
    fi
fi

echo "==> DIY 脚本执行完成"
