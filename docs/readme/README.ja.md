# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

AndroidとApple Silicon Macの間でUSBファイル転送を行うSwiftUIネイティブアプリです。Finder風の最小限のUI、システムのアクセントカラー、ネイティブ検索、Liquid Glassを使用します。Google Android File Transferとは別のアプリとしてインストールします。

## 動作環境とインストール

**Apple Silicon / arm64、macOS 14.0以降**が必要です。macOS 27.2とGalaxy Z Fold7で検証済みですが、macOS 28、Intel、他のデバイスは未検証です。ビルド後に`dist/MacAndFiles.app`を実行するか、ZIPを展開してアプリケーションに移します。libmtp/libusbを同梱しており、実行時にHomebrewやAndroid Studioは不要です。開発用ad-hoc署名のみで、Developer ID署名・公証は未実施です。

## 接続と操作

データ転送用USBケーブルで接続し、ロックを解除して「ファイル転送 / Android Auto」を選びます。Android File Transfer、そのAgent、他のMTPアプリを終了します。デバイスを検索して選択し、接続します。USBデバッグやADBは不要です。フォルダをダブルクリックして移動し、⌘DでMacに保存、⌘UでAndroidに送信します。Finderからのドロップも可能です。⌘↑で上の階層、⌘⇧Nで新規フォルダ、⌘Rで更新します。⌘Fは現在のフォルダ内の名前のみを検索します。クリアまたはEscで一覧を復元し、検索で隠れた項目の選択は解除されます。「その他」にヘルプ、接続解除、診断があります。ログ共有前にファイル名などを確認してください。

## 言語

macOSの優先言語と「システム設定 → 一般 → 言語と地域」のアプリ別言語に従います。変更後は再起動してください。13言語を収録し、非対応言語では英語に戻ります。日付、サイズ、割合は地域設定に従います。ファイル名・デバイス名は変更しません。ライブラリの診断は英語の場合があります。

## 転送の動作

同名項目があると処理を停止し、上書きしません。ダウンロードは一時ファイルに書き込み、サイズ検証後に最終名に移します。アップロードはデバイスが報告するサイズを検証します。取消・失敗時も完了した内容は保持し、Androidに不完全なファイルが残る場合があります。フォルダは最大深度128で再帰コピーし、シンボリックリンクと特殊ファイルは拒否します。進行率は操作全体のファイル数とバイト数に基づきます。MTPで公開された内容のみアクセス可能で、削除・名前変更・Finderボリュームとしてのマウントは未実装です。

## ビルドと検証

Swift 6.2+、macOS 26+ SDK、libmtp 1.1.23、libusb 1.0.30が必要です。スクリプトはバージョンとソースのSHA-256を検証し、動的ライブラリと対応ソースを同梱します。ソースアーカイブにはビルド成果物や私的な診断を含めません。以下は読み取り専用の診断で、汎用ファイル操作CLIやMCPではありません。`--verify-transfer`はUUID付きテストファイルを書き込みます。GUIを切断し、許可されたテスト機器のみで実行して残留物を確認してください。

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

## ライセンスと貢献

コード・スクリプト・文書は**MIT**、Androidロボットは**CC BY 3.0**、libmtp/libusbは**LGPL-2.1-or-later**です。ライセンスと出典を保持してください。AndroidはGoogle LLCの商標で、このアプリは公式ではありません。MacAndFilesは開発名です。公開前にブランドと公証の要件を確認してください。完全な技術資料は英語READMEにあります。貢献時はAGENT.mdを参照してください。この作業フローではGitHub公開を行っていません。

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## ターミナルとエージェント

アプリのインストール後、`scripts/install-cli.sh` で `maf` を導入します。`maf devices` と `maf storages --device "ID"` で ID を確認します。一覧、アップロード、ダウンロード、フォルダ作成については `maf help` と [CLI ガイド](../CLI.md) を参照してください。結果は JSON、失敗時はエラーコードと非ゼロの終了状態を返します。CLI 使用前に GUI の接続を解除してください。

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

macOS 14+ 向けにビルド。macOS 27.2 で検証済み。旧バージョンの実機検証は未実施です。Liquid Glass は macOS 26+。

総ファイル数、完了数、全体の進捗、平均速度、残り時間の目安を表示。停止しても完了したファイルは保持されます。

その他 → ターミナルとエージェントから maf をインストール。必要なら ~/.local/bin を PATH に追加。CLI 操作前に GUI 接続を切断してください。

maf は同じ転送エンジンを使い、JSON 結果、安定したエラーコード、USB セッション状態を提供します。

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/ja/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
