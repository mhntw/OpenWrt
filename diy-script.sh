#!/bin/bash
# OpenWrt DIY script (主脚本)
# 正确执行顺序：feeds update/install → 修改文件 → 完成

# 1. 更新并安装 feeds（必须先执行！）
./scripts/feeds update -a
./scripts/feeds install -a

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
    sed -i 's|../..\/luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' "$mk" 2>/dev/null
    sed -i 's|../..\/lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' "$mk" 2>/dev/null
    sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' "$mk" 2>/dev/null
    sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' "$mk" 2>/dev/null
done

# 5. 取消主题默认设置（防止主题包强制设置默认主题）
find package/luci-theme-*/* -type f -name '*luci-theme-*' 2>/dev/null | while read -r f; do
    sed -i '/set luci.main.mediaurlbase/d' "$f" 2>/dev/null
done

# 6. 设置版本号为编译日期（兼容 lean feed 存在/不存在两种场景）
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    date_version=$(date +"%y.%m.%d")
    orig_version=$(grep DISTRIB_REVISION= package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
    sed -i "s/${orig_version}/R${date_version} by Haiibo/g" \
        package/lean/default-settings/files/zzz-default-settings
fi

echo "✅ DIY script 执行完成"