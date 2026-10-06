# Contributor and agent guide

This guide is for people and coding agents modifying MacAndFiles. Read README.md, THIRD_PARTY_NOTICES.md and VALIDATION.md before changing behavior or preparing a release.

## Structure

- Sources/MacAndFiles/MacAndFilesApp.swift: app scene, commands and CLI dispatch.
- ContentView.swift: native split-view sidebar, toolbar, path bar, file table and status UI.
- AppDelegate.swift: application lifecycle, busy-exit guard and USB connection help.
- Localization.swift and Resources/*.lproj: Foundation localization, runtime formats and native plural rules.
- AppModel.swift: main-actor view state, serial asynchronous USB tasks and file dialogs.
- MTPTransport.swift: libmtp session, storage, object and streaming operations. MTP sessions must remain serialized.
- Types.swift: shared models and transfer engine safety rules.
- TransferProgress.swift: thread-safe cancellation, whole-operation inventory, progress and failure snapshots.
- Compatibility.swift: macOS 26 Liquid Glass and macOS 14 native fallbacks; guard new APIs by availability.
- CLIInstallation.swift: per-user launcher installer; preflight both maf/aft and never replace unrelated tools.
- CLI.swift: strict agent command parsing, remote-path resolution and injectable device backend. CLIRunner.swift: JSON stdout, stderr progress and signal cancellation.
- DeviceAccess.swift: per-device cross-process USB lock shared by GUI, CLI and diagnostics. Never delete lock files while running; doing so can bypass the lock.
- Sources/CLILauncher/main.c: bundled native maf launcher, separately signed before signing the app.
- AppInfo.swift: public name and bundle version metadata; keep fallback values synchronized with Info.plist.
- DeviceVerification.swift: isolated UUID fixture-based device round-trip checks.
- Sources/CLibMTP: upstream libmtp header and Swift system-library module.
- Tests/TransferEngineTests.swift: standalone Foundation tests; no full Xcode/XCTest installation is required.
- Resources/Icon/AppIcon-master.png: selected original 08 artwork (Android holding a document on blue). Build input; do not substitute 08-B or 08-C without a design decision.
- design/: previous design concepts and prompts, retained for contributors.
- scripts/: build, icon generation, tests, source/license packaging.

## Build and change workflow

Use Apple Silicon macOS, Swift 6.2+ and macOS 26+ SDK. Minimum deployment is 14.0. scripts/build-libraries.sh compiles the pinned libmtp 1.1.23 and libusb 1.0.30 source archives for the same target; do not substitute newer-target Homebrew binaries.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

The first release build downloads two upstream source archives and verifies their hashes. Run scripts/fetch-third-party-sources.sh separately to populate the cache. Release outputs are under dist/ and ignored by Git. Icon regeneration uses AppKit and iconutil, requiring no image-generation account or key.

For UI changes, use native macOS controls, system accent color and semantic materials. Check both appearances and small icon sizes. Update the selected source PNG to change the icon, then rebuild the ICNS. Native file-transfer UI should remain usable during asynchronous operations.

Keep toolbar search native with SwiftUI searchable; avoid fixed-width TextField wrappers or extra search backgrounds. Preserve ⌘F, system clear/Escape behavior and selection pruning when filtering. Apply Liquid Glass to navigation and controls while keeping the file table readable.

Appearance checks with synthetic data validate layout only; separately verify the installed app and real device navigation. Keep personal device screenshots and temporary preview harnesses under ignored dist/, outside public source archives. See .impeccable.md for the user's design preferences.

## Localization

Read docs/LOCALIZATION.md before changing user-facing strings. English is the development language; use L10n.text for both SwiftUI and AppKit/runtime errors. Keep every shipped translation and plural table complete. Preserve placeholders, Unicode fixture bytes and raw device/file names. Do not implement a separate language picker or override macOS language preferences. Update README.md and the linked translated READMEs together; verify native fallback, plural rules and right-to-left layout.

## Transfer invariants

- Serialize MTP operations; multiple applications can contend for the USB interface.
- Preserve root handle semantics (0xFFFFFFFF where required by libmtp).
- Never overwrite existing files silently or allow path traversal from device names.
- Download into a temporary file, check size, then publish the final name. Clean up failed Mac temporary files.
- Preserve Unicode and zero-byte files. Do not follow symlinks or send special files.
- Folder depth is bounded; progress reports whole-operation counts and bytes, with active-file progress retained in the CLI contract. Counts must change only after verified publication.
- Cancellation preserves already completed files. Android may retain partial files; report this accurately.
- Device verification creates and removes only its own UUID fixtures. Do not mutate unrelated device data.

Run scripts/test.sh for transfer changes. Use --diagnose or --probe for read-only hardware checks. Run --verify-transfer only with an explicitly designated test device and permission to create its disposable fixtures; disconnect the GUI session first. Existing authorization in a user session applies. Do not declare another OS or device supported based solely on compilation or mock tests.

## Packaging and release

scripts/build-app.sh stages signing outside synced/File Provider workspaces, rewrites library paths to @rpath and produces the arm64 ZIP. Preserve this because synced directories can reattach Finder metadata that invalidates strict signing. Verify the extracted ZIP and installed app, not just the source build. Ad-hoc signatures are local development signatures; Developer ID signing and notarization are separate public-distribution steps.

Keep version metadata in Resources/Info.plist and ensure diagnostics report it from the bundle. Update VALIDATION.md and CHANGELOG.md for meaningful releases. Review docs/RELEASING.md before publishing. Do not include private device listings, user paths, diagnostics or credentials in public issues or source archives.

## Licenses

Project-owned code/docs/scripts: MIT. libmtp header and bundled libraries: LGPL-2.1-or-later. Robot artwork: CC BY 3.0 with Google attribution. Preserve notices and bundled corresponding library sources. Do not relabel the entire repository as MIT or remove the Android robot credit. Preserve the independent-project and Android trademark notices in THIRD_PARTY_NOTICES.md.

Keep changes focused and document actual verification and remaining limits. Prefer meaningful tests for transfer safety over tests that mirror UI implementation details.

## Agent CLI

Read docs/CLI.md before changing the maf contract. Keep schemaVersion, stable error codes, exit codes and stdout JSON compatible. Unknown commands must fail without launching the GUI. Never select a different device/storage silently. Keep library diagnostics off stdout. Partial failure must preserve and report completed items; upload file receipts contain parentID, not an invented object ID. scripts/install-cli.sh installs maf and the aft compatibility alias after checking both names for unrelated tools. The Swift package and target are MacAndFiles. Keep the stable bundle identifier local.androidbridge.mac and USB lock directory for existing macOS preferences and cross-version device locking. Historical AndroidBridge-Test fixture prefixes and verification bytes are intentionally unchanged. The selected public name is MacAndFiles.

## Website

Edit website/assets and the 13 complete website/locales JSON files; scripts/build-site.py regenerates docs/. Never hand-edit generated HTML. scripts/test-site.py checks copy coverage, assets, language URLs and RTL. Keep app screenshots synthetic, explicitly captioned, and sourced from the actual UI. Do not publish personal device screenshots. Public release links must point to an existing matching artifact.

The primary site is https://macandfiles.pages.dev; GitHub Pages remains a mirror. Follow docs/WEBSITE.md for manual Cloudflare deployment. Use the pinned website/package-lock.json and website/wrangler.jsonc; confirm the intended account and production branch before publishing. A Git push does not deploy Cloudflare Pages.
