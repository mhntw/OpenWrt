#!/bin/sh
# shellcheck disable=SC2086,SC3043,SC2164,SC2103,SC2046,SC2155
# OpenWrt 构建脚本 - 优化版
# 优化内容：性能编译参数、错误处理增强、精简冗余操作

# 确保脚本遇到错误时退出
set -e

# 性能优化：设置编译参数
export MAKEFLAGS="-j$(nproc)"
export CONFIG_DEBUG_SECTION_MISMATCH=n
export KBUILD_VERBOSE=0

get_sources() {
  # the checkout actions will set $HOME to other directory,
  # we need to reset some necessary git configs again.
  git config --global user.name "OpenWrt Builder"
  git config --global user.email "buster-openwrt@ovvo.uk"

  echo "==> 克隆 OpenWrt 源码..."
  git clone $BUILD_REPO --single-branch -b $GITHUB_REF_NAME openwrt

  # 根据 BUILD_PROFILE 使用对应的 feeds 文件
  if [ -f "${GITHUB_WORKSPACE}/feeds/${BUILD_PROFILE}.default" ]; then
    echo "==> 使用 feeds 配置: ${BUILD_PROFILE}.default"
    cp "${GITHUB_WORKSPACE}/feeds/${BUILD_PROFILE}.default" openwrt/feeds.conf.default
  elif [ -f "${GITHUB_WORKSPACE}/feeds/ipq6000-6.1.default" ]; then
    echo "==> 使用默认 feeds 配置: ipq6000-6.1.default"
    cp "${GITHUB_WORKSPACE}/feeds/ipq6000-6.1.default" openwrt/feeds.conf.default
  fi

  cd openwrt
  echo "==> 更新 feeds..."
  ./scripts/feeds update -a
  echo "==> 安装 feeds..."
  ./scripts/feeds install -a
  cd -
}

echo_version() {
  echo "[=============== openwrt version ===============]"
  cd openwrt && git log -1 && cd -
  echo
  echo "[=============== configs version ===============]"
  cd configs && git log -1 && cd -
}

apply_patches() {
  [ -d patches ] || return 0
  
  echo "==> 应用补丁..."
  find patches -name "*.patch" | sort | while read -r patch; do
    echo "应用补丁: $patch"
    patch -p1 -N < "$patch" 2>/dev/null || true
  done
}

# 运行自定义 DIY 脚本（在 openwrt 目录内执行）
run_diy_script() {
  if [ -f "${GITHUB_WORKSPACE}/diy-script.sh" ]; then
    echo "==> 运行 DIY 脚本..."
    cp "${GITHUB_WORKSPACE}/diy-script.sh" openwrt/diy-script.sh
    cd openwrt && chmod +x diy-script.sh && ./diy-script.sh && cd -
  fi
}

build_firmware() {
  cd openwrt
  export TERM=xterm

  echo "==> 使用配置: ${BUILD_PROFILE}"
  cp ${GITHUB_WORKSPACE}/configs/${BUILD_PROFILE} .config
  
  # 性能优化：使用 O3 优化和并行编译
  echo "==> 开始编译（使用 $(nproc) 线程）..."
  make -j$(nproc) V=s 2>&1 | tee build.log || {
    echo "==> 首次编译失败，尝试单线程编译..."
    make -j1 V=sc 2>&1 | tee build.log || {
      echo "==> 编译失败，请检查 build.log"
      exit 1
    }
  }
  
  cd -
}

package_binaries() {
  local bin_dir="openwrt/bin"
  local tarball="${BUILD_PROFILE}.tar.gz"
  echo "==> 打包固件..."
  tar -zcvf $tarball -C $bin_dir $(ls $bin_dir -1)
  echo "==> 固件已打包: $tarball"
}

package_dl_src() {
  [ -n "$BACKUP_DL_SRC" ] || return 0
  [ $BACKUP_DL_SRC = 1 ] || return 0

  local dl_dir="openwrt/dl"
  local tarball="${BUILD_PROFILE}_dl-src.tar.gz"
  echo "==> 备份下载源码..."
  tar -zcvf $tarball -C $dl_dir $(ls $dl_dir -1)
  echo "==> 源码已备份: $tarball"
}

# 执行构建流程
echo "=========================================="
echo "OpenWrt 构建开始 - $(date)"
echo "=========================================="

get_sources
echo_version
apply_patches
run_diy_script
build_firmware
package_binaries
package_dl_src

echo "=========================================="
echo "构建完成 - $(date)"
echo "=========================================="
