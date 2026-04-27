#!/bin/bash
# OpenWrt DIY script - 在 feeds install 之后执行
# 包含所有自定义修改

set -e

# 1. 应用本地 patches
if [ -d "$GITHUB_WORKSPACE/patchs" ]; then
    find $GITHUB_WORKSPACE/patchs -name "*.patch" | sort | while read -r patch; do
        local dir=$(cd "$(dirname "$patch")" && pwd)
        local patch_file=$(basename "$patch")
        # 确定应用到 openwrt 内的哪个目录
        local target_dir=""
        case "$patch_file" in
            0001-*) target_dir="package/luci/applications/luci-app-statuspro" ;;
            0002-*) target_dir="package/luci/applications/luci-app-statuspro" ;;
            *)     target_dir="." ;;
        esac
        if [ -d "$target_dir" ]; then
            patch -p1 -N < "$patch" 2>/dev/null || true
        fi
    done
fi

# 2. 修复 hostapd 报错
if [ -d "package/network/services/hostapd/patches" ]; then
    cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch \
        package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
fi

# 3. 修复 armv8 设备 xfsprogs 报错
if [ -f "feeds/packages/utils/xfsprogs/Makefile" ]; then
    sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' \
        feeds/packages/utils/xfsprogs/Makefile
fi

# 4. 修改 Makefile 中的路径引用（处理第三方包）
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | while read -r mk; do
    sed -i 's|../..\/luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' "$mk" 2>/dev/null || true
    sed -i 's|../..\/lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' "$mk" 2>/dev/null || true
    sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' "$mk" 2>/dev/null || true
    sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' "$mk" 2>/dev/null || true
done

# 5. 取消主题默认设置
find package/luci-theme-*/* -type f 2>/dev/null | while read -r f; do
    sed -i '/set luci.main.mediaurlbase/d' "$f" 2>/dev/null || true
done

# 6. 设置版本号（兼容 lean feed 存在/不存在两种场景）
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    date_version=$(date +"%y.%m.%d")
    orig_version=$(grep DISTRIB_REVISION= package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
    sed -i "s/${orig_version}/R${date_version} by Haiibo/g" \
        package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
fi

echo "DIY script done"