#!/bin/sh
# shellcheck disable=SC2086,SC3043,SC2164,SC2103,SC2046,SC2155
# OpenWrt 构建脚本 - 优化版 v2
# 优化内容：ccache 启用、并行编译 + OOM 回退、浅克隆、精简日志

# 确保脚本遇到错误时退出
set -e

get_sources() {
  git config --global user.name "OpenWrt Builder"
  git config --global user.email "buster-openwrt@ovvo.uk"

  echo "==> 克隆 OpenWrt 源码（浅克隆）..."
  git clone $BUILD_REPO --single-branch --depth=1 -b $GITHUB_REF_NAME openwrt

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

run_diy_script() {
  echo "==> 跳过 DIY 脚本（已迁移至 init-settings.sh）"
}

build_firmware() {
  cd openwrt
  export TERM=xterm

  echo "==> 使用配置: ${BUILD_PROFILE}"
  cp ${GITHUB_WORKSPACE}/configs/${BUILD_PROFILE} .config

  # 启用 ccache 加速增量编译
  export CCACHE_MAXSIZE="2G"
  export CCACHE_COMPRESS="1"

  # 并行编译 + OOM 回退策略
  CPU_CORES=$(nproc)
  echo "==> 开始编译（${CPU_CORES} 线程 + ccache）..."
  make -j${CPU_CORES} V=i || {
    echo "==> 多线程编译失败，回退单线程重试..."
    make -j1 V=sc || {
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
