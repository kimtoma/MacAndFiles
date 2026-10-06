# Changelog

## 1.0.0 build 9 — 2026-10-06

- Added whole-operation inventory, counts, byte progress, average speed, ETA and failure details to GUI and CLI.
- Added native per-user CLI installation and advisory device ownership status.
- Lowered the arm64 deployment target to macOS 14 and rebuilt both pinned libraries for that target. Liquid Glass and newer APIs have native fallbacks; older OS runtime validation remains pending.
- Added Developer ID signing/notarization scripts; default artifacts remain ad-hoc signed.
- Added a 13-language static website, with a restrained product-first design, an actual native UI preview using sample files, RTL and language-specific URLs.
- Verified Galaxy Z Fold7 round trips for 4 GiB + 1 MiB and 2,000 small files. CLI cancellation avoids an additional CloseSession wait; the device can still require protocol timeout/reconnection.

## 1.0.0 build 8 — 2026-10-06

- Rebranded the app, Swift package, contributor guides, all 13 READMEs and release archives as MacAndFiles.
- Made `maf` the primary native CLI command, retaining `aft` as a compatibility alias and migrating the previous installer symlink safely. The JSON schema and command/error contracts remain compatible; app metadata reflects the new name.
- Preserved the selected 08 artwork, Liquid Glass UI, localization, transfer safety and the stable macOS bundle identifier/device-lock directory.

## 1.0.0 build 7 — 2026-10-06

- Renamed the app and release archives to Android File Transfer; retained the selected 08 icon, native UI and 13 languages.
- Added the `aft` agent CLI: devices, storages, ls, upload, download, mkdir, help and version. JSON output, stable error/exit codes, stderr progress and signal cancellation.
- Shared the transfer engine and per-device cross-process USB locks between GUI and CLI. Added completion receipts for partial failures, without deletion or overwrite commands.
- Added an installer, CLI contract, contributor guidance and CLI safety tests.

## 1.0.0 build 6 — 2026-10-06

- Localized app-owned UI, menus, file panels, help, transfer status and errors in 13 languages using native Foundation bundle resources; English is the development fallback.
- Added native plural rules, regional percentage formatting and right-to-left browser layout with directional path chevrons.
- Made README.md English-first and added 12 linked translated guides, plus localization contributor documentation.
- Added localization checks for all languages, unsupported-language fallback, regional matching, placeholders, plurals and layout direction. Preserved the original 08 icon and transfer safety rules.

## 1.0.0 build 5 — 2026-10-06

- Adopt native macOS Liquid Glass toolbar grouping, a glass path bar and glass connection buttons.
- Replace the custom fixed-width toolbar TextField with SwiftUI's native searchable control, including system focus and clear behavior and a ⌘F command.
- Show search result counts and prune selections hidden by a search filter.
- Verified native search, focus, clearing, selection filtering, resizing and reconnection on Galaxy Z Fold7; checked both appearances with an isolated preview.
- Release build and 11 transfer-safety tests passed; installed build 5 and refreshed distribution packages.

## 1.0.0 build 4 — 2026-10-05

- Simplified the browser into a native resizable/collapsible sidebar, compact path bar, unified toolbar and status bar.
- Removed duplicate branding, large instructional headers and persistent technical labels; connection help and diagnostics are available through menus.
- Added Finder-style file type icons, parent-folder shortcut (⌘↑) and new-folder shortcut (⌘⇧N).
- Split view and app lifecycle code into dedicated files and checked the browser and connection screens in both appearances.
- Preserved the original 08 icon and existing USB transfer behavior. The local Android Transfer app was inspected as a UI reference; its source was not incorporated.

## 1.0.0 build 3 — 2026-10-05

- Adopted the selected original 08 Android Courier icon: green mascot holding a document with transfer arrows on a blue tile.
- Added MIT license for project-owned source, separate robot/library notices, contributor guides and AGENT.md/AGENTS.md.
- Bundled pinned, checksum-verified LGPL library sources and rebuild instructions with release apps.
- Added source archive packaging and a public-release checklist.

## 1.0.0 builds 1–2 — 2026-10-05

- Native SwiftUI browser and libmtp USB transfer, file/folder upload/download, search, mkdir, progress/cancel and diagnostics.
- Finder-style system accent colors and early icon iteration.
- Galaxy Z Fold7 fixture round-trip verification and 11 transfer-safety checks.
