# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

SwiftUI 原生 Android USB 文件传输应用，面向 Apple Silicon Mac。使用 Finder 风格界面、系统强调色、原生搜索和 Liquid Glass。它是独立应用，不会覆盖 Google Android File Transfer。

## 要求与安装

需要 **Apple Silicon / arm64 和 macOS 14.0 或更高版本**。已验证 macOS 27.2 与 Galaxy Z Fold7；macOS 28、Intel 和其他设备尚未验证。构建后运行 `dist/MacAndFiles.app`，或解压应用 ZIP 并放入“应用程序”。libmtp/libusb 已包含，运行时无需 Homebrew 或 Android Studio。应用仅使用开发用 ad-hoc 签名，尚未进行 Developer ID 签名和公证。

## 连接与使用

使用 USB 数据线连接设备，解锁并选择“文件传输 / Android Auto”。退出 Android File Transfer、其后台 Agent 和其他 MTP 应用。选择“搜索设备”，选择设备后连接。无需 USB 调试或 ADB。双击文件夹浏览；⌘D 保存到 Mac，⌘U 发送到 Android，也可拖入 Finder 文件。⌘↑ 返回上一级，⌘⇧N 新建文件夹，⌘R 刷新。⌘F 仅搜索当前文件夹名称；清除或按 Esc 恢复列表。被搜索隐藏的项目会取消选择。“更多”提供帮助、断开连接和诊断记录。分享记录前请检查文件名等信息。

## 语言

应用遵循 macOS 首选语言及“系统设置 → 通用 → 语言与地区”中的应用语言。更改后重新启动。支持 13 种语言，其他语言回退到英语。日期、大小和百分比遵循地区设置；文件名与设备名称保持原样。底层库诊断可能仍为英语。

## 传输行为

同名项目会停止操作，不自动覆盖。下载先写临时文件并检查大小，再改为最终名称；上传检查设备报告的大小。取消或失败保留已完成内容，Android 可能留下不完整文件。文件夹递归复制，深度上限为 128；拒绝符号链接和特殊文件。进度包含整个传输任务的文件数和字节数。只能访问 MTP 公开的内容，不支持删除、重命名或 Finder 卷挂载。

## 构建与验证

需要 Swift 6.2+、macOS 26+ SDK、libmtp 1.1.23 和 libusb 1.0.30。发布脚本校验版本及源码 SHA-256，打包动态库和对应源码。源码归档排除构建产物和私人诊断。以下只读命令用于设备诊断，不是通用文件操作 CLI 或 MCP。`--verify-transfer` 会写入 UUID 测试文件；请先断开 GUI，仅对获准测试的设备运行，检查残留测试对象。

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## 许可与贡献

代码、脚本和文档为 **MIT**；Android 机器人为 **CC BY 3.0**，libmtp/libusb 为 **LGPL-2.1-or-later**。保留许可和第三方声明。Android 是 Google LLC 的商标，本项目不是官方应用。MacAndFiles 是开发名称，公开发布前需审查品牌与公证要求。英文 README 是完整技术参考；贡献请阅读 AGENT.md。此流程尚未上传 GitHub 发布。

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## 终端与代理

安装应用后运行 `scripts/install-cli.sh` 安装 `maf`。使用 `maf devices` 和 `maf storages --device "ID"` 获取设备及存储 ID。支持列出文件、上传、下载和创建文件夹；参见 `maf help` 和 [CLI 文档](../CLI.md)。结果为 JSON，失败返回错误代码和非零退出状态。使用 CLI 前请断开 GUI 的设备连接。

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

面向 macOS 14+ 构建，已在 macOS 27.2 验证；旧版本仍需实机验证。macOS 26+ 支持 Liquid Glass。

查看总文件数、完成数、总体进度、平均速度与预计剩余时间。传输停止时保留已完成文件。

在应用的更多 → 终端和智能体中安装 maf。按需将 ~/.local/bin 加入 PATH。CLI 文件操作前请断开 GUI 连接。

maf CLI 使用相同传输引擎，提供 JSON 结果、稳定错误代码与清晰的 USB 会话状态。

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/zh-Hans/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
