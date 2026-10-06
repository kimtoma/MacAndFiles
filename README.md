# MacAndFiles

<img src="Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](README.md) · [한국어](docs/readme/README.ko.md) · [简体中文](docs/readme/README.zh-Hans.md) · [繁體中文](docs/readme/README.zh-Hant.md) · [Español](docs/readme/README.es.md) · [Português](docs/readme/README.pt-BR.md) · [日本語](docs/readme/README.ja.md) · [Deutsch](docs/readme/README.de.md) · [Français](docs/readme/README.fr.md) · [Русский](docs/readme/README.ru.md) · [हिन्दी](docs/readme/README.hi.md) · [Bahasa Indonesia](docs/readme/README.id.md) · [العربية](docs/readme/README.ar.md)

**Native Android file transfer for Mac.**

A native SwiftUI app for transferring files between an Android device and an Apple Silicon Mac over USB. Its minimal Finder-style browser uses system accent colors, native search and macOS Liquid Glass. This is an independent app, unrelated to Google’s original Android File Transfer.

Project-owned code, scripts and documentation are **MIT**. The Android robot artwork is **CC BY 3.0**, and bundled libmtp/libusb are **LGPL-2.1-or-later**. Preserve [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md). Android is a trademark of Google LLC; this project is not affiliated with Google. Review [public-release requirements](docs/RELEASING.md) before publishing.

## Requirements and installation

- **Apple Silicon / arm64; macOS 14.0 or later.** The tested environment is macOS 27.2 and Galaxy Z Fold7. macOS 14–26 are deployment targets and still need real-device validation. Liquid Glass is used on macOS 26+; earlier versions use native materials and controls. macOS 28, Intel Macs and other devices are not verified; see [validation evidence](VALIDATION.md).
- Build locally or extract `dist/MacAndFiles-macOS-arm64.zip`, then place `MacAndFiles.app` in Applications. libmtp and libusb are bundled; Homebrew and Android Studio are not needed to run the app.
- This is an **ad-hoc signed development build**, without Apple Developer ID signing or notarization. Normal public-download distribution requires the steps in [RELEASING.md](docs/RELEASING.md); another Mac's Gatekeeper acceptance is not verified.

## Connect and transfer

1. Connect Android with a USB data cable, unlock it and select **File Transfer / Android Auto** in its USB notification.
2. Quit Google Android File Transfer and other MTP apps. Its background **Android File Transfer Agent** can also hold the USB interface.
3. Choose **Scan for Devices**, select your device and choose **Connect**. USB debugging and ADB are not required.
4. Double-click folders to browse. Select files or folders and choose **Save to Mac** (⌘D), or use **Send to Android** (⌘U) to select Mac files/folders. You can also drop Finder files/folders into the file list.

The sidebar resizes and collapses. Use the path bar or **⌘↑** to go up; **⌘⇧N** creates a folder. **⌘F** focuses native search, which filters names in the current folder only. Clear or press Escape to restore the list. Moving to another folder clears search, and filtering clears hidden selections. **⌘R** refreshes. Connection help, disconnect and diagnostics are in **More**. Diagnostic logs can include file names and errors; inspect them before sharing.

## Terminal and agents

Use **More → Terminal and Agents → Install CLI** after placing the app in Applications. The app shows installation and USB ownership status. The script provides the same per-user installation:

```sh
scripts/install-cli.sh
maf help
maf devices
maf status
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
maf upload --device "DEVICE_ID" --storage 65537 --from "$HOME/Desktop/example.txt" --to /Download
maf download --device "DEVICE_ID" --storage 65537 --path /Download/example.txt --to "$HOME/Downloads"
maf mkdir --device "DEVICE_ID" --storage 65537 --path /Download/NewFolder
```

Replace device/storage IDs with values returned by discovery. `maf` returns one JSON envelope on stdout, with stable error codes and nonzero exit status on failure. `--progress` sends whole-operation counts, bytes, progress, average speed and estimated time remaining to stderr. GUI and CLI share the transfer engine and an exclusive device lock; disconnect the GUI before using its device in the CLI. See the [CLI contract](docs/CLI.md) for output, exit codes, cancellation and agent integration. The previous `aft` command remains available as a compatibility alias; new integrations should use `maf`.

## Languages and regional settings

The app follows macOS's preferred language and its per-app language setting in **System Settings → General → Language & Region → Applications**. Relaunch after changing the language. There is no separate in-app language preference.

English, Korean, Simplified/Traditional Chinese, Spanish, Brazilian Portuguese, Japanese, German, French, Russian, Hindi, Indonesian and Arabic are included. Unsupported languages fall back to English. Foundation handles language matching and plural rules; dates, byte sizes and percentages follow regional settings. Arabic uses the system's right-to-left layout. File names and device-provided names are preserved; low-level library diagnostics can remain in upstream English.

English is the source README. Translations cover usage, safety, build and licensing; update them alongside it. Translation contributions are welcome. See [localization guide](docs/LOCALIZATION.md).

## Transfer behavior

- Existing names are never silently overwritten. A collision stops the operation.
- Downloads are written to temporary files, checked for size, then moved to their final names. Failed Mac temporary files are cleaned up.
- Uploads check the size reported by the device. Normal transfers check size; the hardware verification command also compares round-trip contents and SHA-256.
- Canceling or failing preserves completed files and folders. Android may retain partial files; refresh and inspect the device.
- Folders are copied recursively, with a depth limit of 128. Symbolic links and special files are rejected. Earlier completed files remain if a later child fails.
- Progress measures the whole batch, including recursive folders. Completion counts change only after a file is verified and published. Transfer Details reports the first failed item; unattempted files are not marked as failures.
- Only files exposed through MTP are accessible. Android may hide app-private data and protected folders.
- Deleting, renaming and mounting as a Finder volume are not implemented.

## Build and verify

Use Apple Silicon, Swift 6.2+ and Command Line Tools with the macOS 26+ SDK. The build downloads and compiles pinned libmtp **1.1.23** and libusb **1.0.30** for arm64/macOS 14.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

The release script verifies SHA-256 of pinned upstream source archives, compiles both libraries for the deployment target, bundles libraries and matching sources, rewrites load paths to `@rpath`, signs the app ad hoc by default and produces the arm64 ZIP. The source archive excludes `dist/`, `.build/`, Git metadata and private diagnostics. When upgrading dependencies, update source URLs, hashes, notices and rebuild instructions together.

The selected original 08 icon is [AppIcon-master.png](Resources/Icon/AppIcon-master.png). [Icon documentation](Resources/Icon/README.md) records its design and prompt. `scripts/build-icon.sh` generates 16–1024 px representations using AppKit and iconutil; no image-generation account or API key is required.

Read-only diagnostics:

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

`--diagnose` detects devices; `--probe` opens a device and reads storage/root listings. The agent CLI described below provides general file operations. These older flags remain diagnostic commands; no MCP server is included.

Hardware verification **writes disposable fixtures** to the designated device. Disconnect the GUI session first and use only a device authorized for testing:

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --verify-transfer --report dist/device-verification.json
```

This requires exactly one connected device. It creates UUID-named `AndroidBridge-Test-…` fixtures, round-trips a Korean-named file, an empty file and a 5 MiB binary in a nested folder, compares contents/SHA-256, and cleans up only its own test objects. It also verifies a root-level file. An error reports fixtures that might remain.

## Dependencies and contributions

[libmtp](https://github.com/libmtp/libmtp) 1.1.23 and [libusb](https://github.com/libusb/libusb) 1.0.30 are separately replaceable dynamic libraries. License texts are under `Resources/Licenses` and in the app bundle. Corresponding sources and [rebuild/replacement instructions](docs/THIRD_PARTY_BUILD.md) ship in `Contents/Resources/ThirdPartySources`. The native About window includes credits.

Read [AGENT.md](AGENT.md) for architecture, modification points and transfer invariants; [AGENTS.md](AGENTS.md) points coding tools to it. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

## Website and release status

The [multilingual website](https://macandfiles.pages.dev/) includes 13 complete language URLs, browser-language selection, RTL layout and an English fallback. Its app preview uses sample files. Edit `website/locales/` and `website/assets/`, then run `python3 scripts/test-site.py` to regenerate `docs/`. Cloudflare Pages deployment instructions are in [docs/WEBSITE.md](docs/WEBSITE.md); the GitHub Pages site remains a mirror.

Public development downloads remain ad-hoc signed until a Developer ID certificate and notarization profile are provided. See [RELEASING.md](docs/RELEASING.md). GUI and CLI still use exclusive USB sessions; a shared session broker and a thin MCP adapter remain future work. Agents can use `maf` now.
