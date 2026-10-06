# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

適用於 Apple Silicon Mac 的 SwiftUI 原生 Android USB 檔案傳輸應用程式。採用 Finder 風格介面、系統強調色、原生搜尋及 Liquid Glass。它是獨立應用程式，不會覆蓋 Google Android File Transfer。

## 需求與安裝

需要 **Apple Silicon / arm64 與 macOS 14.0 或以上版本**。已驗證 macOS 27.2 和 Galaxy Z Fold7；macOS 28、Intel 和其他裝置尚未驗證。建置後執行 `dist/MacAndFiles.app`，或解壓縮應用程式 ZIP 並放入「應用程式」。已包含 libmtp/libusb，執行時不需要 Homebrew 或 Android Studio。目前僅使用開發用 ad-hoc 簽署，尚未進行 Developer ID 簽署及公證。

## 連接與使用

使用 USB 資料線連接、解鎖裝置並選擇「檔案傳輸 / Android Auto」。結束 Android File Transfer、其背景 Agent 和其他 MTP 應用程式。選擇「搜尋裝置」，選取裝置後連接。不需要 USB 偵錯或 ADB。雙擊檔案夾瀏覽；⌘D 儲存到 Mac，⌘U 傳送到 Android，也可拖入 Finder 檔案。⌘↑ 前往上一層，⌘⇧N 新增檔案夾，⌘R 重新整理。⌘F 僅搜尋目前檔案夾名稱；清除或按 Esc 恢復列表。被搜尋隱藏的項目會取消選取。「更多」提供說明、中斷連線及診斷記錄。分享記錄前請檢查檔案名稱等資訊。

## 語言

應用程式遵循 macOS 偏好語言及「系統設定 → 一般 → 語言與地區」中的應用程式語言。變更後重新啟動。支援 13 種語言，其他語言回退至英文。日期、大小和百分比遵循地區設定；檔案名稱與裝置名稱保持原樣。底層程式庫診斷可能仍為英文。

## 傳輸行為

同名項目會停止操作，不自動覆寫。下載先寫入暫存檔並檢查大小，再移至最終名稱；上傳檢查裝置回報的大小。取消或失敗保留已完成內容，Android 可能留下不完整檔案。檔案夾遞迴拷貝，深度上限為 128；拒絕符號連結及特殊檔案。進度包含整個傳輸工作的檔案數及位元組數。只能存取 MTP 公開的內容，不支援刪除、重新命名或 Finder 卷宗掛載。

## 建置與驗證

需要 Swift 6.2+、macOS 26+ SDK、libmtp 1.1.23 和 libusb 1.0.30。發行指令碼驗證版本及原始碼 SHA-256，包含動態程式庫及對應原始碼。原始碼封存排除建置產物及私人診斷。以下唯讀命令用於裝置診斷，並非一般檔案操作 CLI 或 MCP。`--verify-transfer` 會寫入 UUID 測試檔案；請先中斷 GUI 連線，僅在獲准測試的裝置執行並檢查殘留測試項目。

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

## 授權與貢獻

程式碼、指令碼與文件為 **MIT**；Android 機器人為 **CC BY 3.0**，libmtp/libusb 為 **LGPL-2.1-or-later**。請保留授權和第三方聲明。Android 是 Google LLC 的商標，本專案並非官方應用程式。MacAndFiles 是開發名稱，公開發行前須審查品牌與公證要求。英文 README 是完整技術參考；貢獻前請閱讀 AGENT.md。此流程尚未上傳 GitHub 發行。

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## 終端機與代理

安裝應用程式後執行 `scripts/install-cli.sh` 安裝 `maf`。使用 `maf devices` 和 `maf storages --device "ID"` 取得裝置與儲存空間 ID。支援檔案清單、上傳、下載與建立資料夾；請參閱 `maf help` 和 [CLI 文件](../CLI.md)。結果為 JSON，失敗會回傳錯誤碼與非零結束狀態。使用 CLI 前請中斷 GUI 的裝置連線。

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

以 macOS 14+ 為目標建置，已在 macOS 27.2 驗證；舊版本仍需實機驗證。macOS 26+ 支援 Liquid Glass。

查看總檔案數、完成數、整體進度、平均速度與預估剩餘時間。傳輸停止時保留已完成檔案。

在應用程式的更多 → 終端機與代理中安裝 maf。按需將 ~/.local/bin 加入 PATH。CLI 檔案操作前請中斷 GUI 連線。

maf CLI 使用相同傳輸引擎，提供 JSON 結果、穩定錯誤碼與清楚的 USB 工作階段狀態。

[MacAndFiles](https://macandfiles.pages.dev/zh-Hant/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
