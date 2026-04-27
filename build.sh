#!/bin/sh
# shellcheck disable=SC2086,SC3043,SC2164,SC2103,SC2046,SC2155

get_sources() {
  # the checkout actions will set $HOME to other directory,
  # we need to reset some necessary git configs again.
  git config --global user.name "OpenWrt Builder"
  git config --global user.email "buster-openwrt@ovvo.uk"

  git clone $BUILD_REPO --single-branch -b $GITHUB_REF_NAME openwrt

  # 根据 BUILD_PROFILE 使用对应的 feeds 文件
  if [ -f "${GITHUB_WORKSPACE}/feeds/${BUILD_PROFILE}.default" ]; then
    cp "${GITHUB_WORKSPACE}/feeds/${BUILD_PROFILE}.default" openwrt/feeds.conf.default
  elif [ -f "${GITHUB_WORKSPACE}/feeds/ipq6000-6.1.default" ]; then
    cp "${GITHUB_WORKSPACE}/feeds/ipq6000-6.1.default" openwrt/feeds.conf.default
  fi

  cd openwrt
  ./scripts/feeds update -a
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

  find patches -name "*.patch" | sort | while read -r patch; do
    patch -p1 -N < "$patch" 2>/dev/null || true
  done
}

# 运行自定义 DIY 脚本（在 openwrt 目录内执行）
run_diy_script() {
  if [ -f "${GITHUB_WORKSPACE}/diy-script.sh" ]; then
    cp "${GITHUB_WORKSPACE}/diy-script.sh" openwrt/diy-script.sh
    cd openwrt && chmod +x diy-script.sh && ./diy-script.sh && cd -
  fi
}

build_firmware() {
  cd openwrt
  export TERM=xterm

  cp ${GITHUB_WORKSPACE}/configs/${BUILD_PROFILE} .config
  make -j$(($(nproc) + 1)) V=e || make -j1 V=sc || exit 1

  cd -
}

package_binaries() {
  local bin_dir="openwrt/bin"
  local tarball="${BUILD_PROFILE}.tar.gz"
  tar -zcvf $tarball -C $bin_dir $(ls $bin_dir -1)
}

package_dl_src() {
  [ -n "$BACKUP_DL_SRC" ] || return 0
  [ $BACKUP_DL_SRC = 1 ] || return 0

  local dl_dir="openwrt/dl"
  local tarball="${BUILD_PROFILE}_dl-src.tar.gz"
  tar -zcvf $tarball -C $dl_dir $(ls $dl_dir -1)
}

get_sources
echo_version
apply_patches
run_diy_script
build_firmware
package_binaries
package_dl_src