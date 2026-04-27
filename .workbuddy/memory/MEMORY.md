# OpenWrt 项目长期记忆

## 项目概述
- GitHub 仓库: mnhtw/OpenWrt
- 本地路径: /Users/chen/WorkBuddy/20260427135026/OpenWrt
- CI 工作流是 workflow_dispatch 模式（手动触发），不会自动运行

## CI 编译问题（2026-04-27 修复）
- 目标设备: jdc_ax1800-pro (IPQ60xx, 6.6 内核, eMMC)
- 曾出现 `8devices_mango-dvk`（28MB 闪存）被自动构建导致失败
- 固件 113MB > 28MB 限制，fwtool 报 "too big" 错误
- 修复: 在每个 `make defconfig` 前都强制过滤设备配置
