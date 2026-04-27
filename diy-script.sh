#!/bin/bash
# OpenWrt DIY script - 在 feeds install 之后执行
# 优化版：增强稳定性、精简冗余操作

set -e

echo "==> 开始执行 DIY 脚本..."

# 1. 应用本地 patches（优化：只应用存在的补丁）
if [ -d "$GITHUB_WORKSPACE/patchs" ] && [ "$(ls -A $GITHUB_WORKSPACE/patchs/*.patch 2>/dev/null)" ]; then
    echo "==> 应用补丁..."
    find $GITHUB_WORKSPACE/patchs -name "*.patch" | sort | while read -r patch; do
        patch_name=$(basename "$patch")
        case "$patch_name" in
            0001-*|0002-*)
                target_dir="package/luci/applications/luci-app-statuspro"
                ;;
            *)
                target_dir="."
                ;;
        esac
        if [ -d "$target_dir" ]; then
            echo "应用: $patch_name -> $target_dir"
            patch -p1 -N < "$patch" 2>/dev/null || echo "补丁 $patch_name 已应用或跳过"
        fi
    done
fi

# 2. 修复 hostapd 报错（如果存在）
if [ -d "package/network/services/hostapd/patches" ]; then
    if [ -f "$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch" ]; then
        echo "==> 修复 hostapd MBO 模块..."
        cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch \
            package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
    fi
fi

# 3. 修复 armv8 设备 xfsprogs 报错（如果存在）
if [ -f "feeds/packages/utils/xfsprogs/Makefile" ]; then
    echo "==> 修复 xfsprogs..."
    sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' \
        feeds/packages/utils/xfsprogs/Makefile
fi

# 4. 修改 Makefile 中的路径引用（处理第三方包）
echo "==> 修复第三方包路径..."
find package/*/ -maxdepth 2 -path "*/Makefile" 2>/dev/null | while read -r mk; do
    sed -i 's|../..\/luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' "$mk" 2>/dev/null || true
    sed -i 's|../..\/lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' "$mk" 2>/dev/null || true
    sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' "$mk" 2>/dev/null || true
    sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' "$mk" 2>/dev/null || true
done

# 5. 取消主题默认设置（避免强制主题）
echo "==> 清理主题默认设置..."
find package/luci-theme-*/* -type f 2>/dev/null | while read -r f; do
    sed -i '/set luci.main.mediaurlbase/d' "$f" 2>/dev/null || true
done

# 6. 设置版本号（兼容 lean feed 存在/不存在两种场景）
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    echo "==> 设置版本号..."
    date_version=$(date +"%y.%m.%d")
    orig_version=$(grep DISTRIB_REVISION= package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
    sed -i "s/${orig_version}/R${date_version} by mhntw/g" \
        package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
    echo "版本设置为: R${date_version}"
fi

# 7. 优化：清理编译缓存（可选）
if [ "$CLEAN_BUILD" = "1" ]; then
    echo "==> 清理编译缓存..."
    make clean 2>/dev/null || true
fi

echo "==> DIY 脚本执行完成"
