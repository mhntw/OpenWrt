# OpenWrt CI 监控记录

## 2026-04-27 15:12 - 发现并修复固件过大编译失败

**CI 状态**: 最近 3 次运行全部失败（#24976255065, #24970161605, #24957804565）

**根本原因**:
- `8devices_mango-dvk`（闪存 28MB）被自动构建，但固件 113MB 远超限制
- 工作流中的 `Force Single Device Build` 步骤虽然只选中了 `jdc_ax1800-pro`
- 但后续 `Download DL Package` 和 `Compile Firmware` 步骤中的 `make defconfig` 恢复了多设备配置
- `CONFIG_TARGET_MULTI_PROFILE=y` 的 sed 替换使用 `s///` 模式无法匹配已经是 `# CONFIG_TARGET_MULTI_PROFILE is not set` 的行

**修复措施** (commit d46ad59):
- 在每一个调用 `make defconfig` 的步骤前都添加设备过滤逻辑
- 使用 `sed -i '/^CONFIG_TARGET_MULTI_PROFILE=y/d'` 替代 `s///` 模式
- 在 Compile Firmware 步骤最终编译前也强制执行一次过滤

**推送状态**: 已推送到 main，但工作流是 workflow_dispatch 模式，需手动触发新构建
