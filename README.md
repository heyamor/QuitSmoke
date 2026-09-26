# 无烟日记（QuitSmoke）

个人自用的原生 iPhone 戒烟记录 App。使用 SwiftUI 编写，数据只保存在本机，不需要账号、网络或服务器。

## 功能

- 戒烟日、烟龄、原每日吸烟量、每包支数和价格
- 当前无烟时长、连续无烟天数、最长无烟纪录、累计少抽和省钱
- 每日无烟/吸烟打卡，历史不会因复吸清零，可单独重新开始计时
- 烟瘾记录：时间、强度、触发场景、情绪、是否扛过和一句回顾
- 复吸事件：时间、支数、原因和备注
- 恢复里程碑卡片
- 周/月烟瘾次数趋势和高频触发场景统计
- 可维护自定义触发标签
- 体重、睡眠和精力记录
- 多个本地提醒时间
- JSON 备份和 CSV 表格导出

## 用 Xcode 安装到自己的 iPhone

1. 用 Xcode 打开 `QuitSmoke.xcodeproj`。
2. 在 **TARGETS > QuitSmoke > Signing & Capabilities** 选择你的 Team。
3. 连接 iPhone，选择设备后运行。
4. 首次运行按 iPhone 提示信任开发者。

## 导出数据

打开 **设置 > 数据导出**，可导出 JSON 备份或 CSV 表格。重新安装 App 前建议先导出 JSON。

## GitHub Actions

工程包含 `.github/workflows/build-signed-ipa.yml`，可在 GitHub 的 **Actions > Build unsigned IPA > Run workflow** 生成未签名 IPA。安装前需要用自己的签名工具重新签名。

## 开发要求

- iOS 17.0+
- SwiftUI / Charts
- Xcode 15 或更新版本
- 无第三方依赖
