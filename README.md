# 无烟日记（QuitSmoke）

一个个人自用的原生 iPhone 戒烟记录 App。使用 SwiftUI 编写，不需要账号、网络或服务器；数据仅以 JSON 文件保存在 App 自己的设备沙盒中。

## 功能

- 首次设置戒烟开始时间、原每日吸烟量、每包支数和价格
- 显示本次戒烟时长、累计少抽支数、省下金额、连续无烟天数
- 每日记录“无烟”或实际吸烟支数
- 记录烟瘾强度、触发原因和是否扛过去
- 最近 7 天概览、打卡历史、烟瘾统计和戒烟阶段历史
- 可选每日本地通知
- 复吸不会清空历史；可单独重新开始当前计时

## 用 Xcode 安装到自己的 iPhone（Personal Team）

1. 在 Mac 上安装并打开完整版 Xcode。
2. 用数据线连接 iPhone；在手机上点“信任”，并按提示开启“开发者模式”。
3. 双击 `QuitSmoke.xcodeproj` 打开工程。
4. 在左侧选择蓝色的 **QuitSmoke** 工程，再选择 **TARGETS > QuitSmoke > Signing & Capabilities**。
5. 勾选 **Automatically manage signing**，在 **Team** 选择自己的 Apple ID（Personal Team）。若尚未登录，在 Xcode 的 **Settings > Accounts** 添加 Apple ID。
6. 若 Bundle Identifier 提示重复，把 `com.personal.quitsmoke` 改成自己的唯一值，例如 `com.你的英文名.quitsmoke`。
7. 在 Xcode 顶部运行设备中选择自己的 iPhone，点击运行按钮（或按 `⌘R`）。
8. 首次运行若被系统拦截，在 iPhone 的 **设置 > 通用 > VPN 与设备管理** 中信任对应开发者。

免费 Apple ID 的个人签名通常需要定期重新连接 Xcode 安装；具体有效期由 Apple 当前规则决定。

## 在 GitHub Actions 生成签名 IPA

工程包含 `.github/workflows/build-signed-ipa.yml`，可在 GitHub 的 Actions 页面手动运行。工作流支持包含已注册 iPhone 的 Development 或 Ad Hoc 描述文件，并会自动读取 Team ID、Bundle ID 和签名方式。

在仓库 **Settings > Secrets and variables > Actions** 中添加以下 Repository secrets：

- `IOS_P12_BASE64`：`.p12` 文件转换成 Base64 后的内容
- `IOS_P12_PASSWORD`：导出 `.p12` 时设置的密码
- `IOS_PROVISIONING_PROFILE_BASE64`：`.mobileprovision` 文件转换成 Base64 后的内容
- `IOS_KEYCHAIN_PASSWORD`：任意新生成的长随机密码，仅用于 Actions 临时钥匙串

在 Mac 终端生成可粘贴的 Base64 内容：

```sh
base64 < certificate.p12 | tr -d '\n' | pbcopy
base64 < profile.mobileprovision | tr -d '\n' | pbcopy
```

添加 Secrets 后，进入 **Actions > Build signed IPA > Run workflow**。成功后在该次运行页面的 **Artifacts** 中下载 `QuitSmoke-signed-ipa`，解压即可得到 `.ipa`。

安全提示：不要把 `.p12`、证书密码或 `.mobileprovision` 直接提交进 Git 仓库。Base64 只是编码，不是加密；必须放在 GitHub Secrets 中。

## 开发要求

- iOS 17.0+
- SwiftUI
- Xcode 15 或更新版本
- 无第三方依赖
