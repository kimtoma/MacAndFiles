# Third-party notices

The project's own Swift code, scripts and documentation are licensed under MIT (see LICENSE). Third-party code and artwork retain the terms below; the root MIT license does not replace them.

## Android robot artwork — CC BY 3.0

The Android robot is reproduced or modified from work created and shared by Google and used according to terms described in the Creative Commons 3.0 Attribution License.

- Original author: Google. Work: Android robot.
- Source and brand guidance: https://developer.android.com/distribute/marketing-tools/brand-guidelines
- License: https://creativecommons.org/licenses/by/3.0/
- License text: Resources/Licenses/Android-CC-BY-3.0.txt
- Modifications: AI-generated soft 3D reinterpretation, holding a document with opposing transfer arrows, on a blue rounded-square tile. Other generated robot concepts are retained in design/.
- Artwork covered: Resources/Icon/AppIcon-master.png, generated Resources/AppIcon.icns, robot concept images and their previews in design/.
- This project makes its own contributions to these robot illustrations available under CC BY 3.0 as well. Preserve the attribution and identify your modifications when redistributing them.

Android is a trademark of Google LLC. This independent project is not affiliated with or endorsed by Google. Copyright licenses do not grant trademark rights. Public branding must follow Google's current brand guidance, including the application-naming guidance ("for Android") and any required brand review. "MacAndFiles" is the selected project name, not a claim of branding approval.

## libmtp 1.1.23 — LGPL-2.1-or-later

- Upstream: https://github.com/libmtp/libmtp
- Source archive: https://downloads.sourceforge.net/project/libmtp/libmtp/1.1.23/libmtp-1.1.23.tar.gz
- SHA-256: 74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed
- Covered: Sources/CLibMTP/libmtp.h and bundled libmtp.9.dylib.
- License text: Resources/Licenses/libmtp-LGPL-2.1.txt. Preserve upstream copyright notices in the header and source archive.
- The upstream code is unmodified. Packaging changes only the dylib ID and libusb load path. Built from the verified upstream archive for arm64/macOS 14, with --disable-mtpz, --disable-static, --disable-dependency-tracking and --disable-silent-rules.

## libusb 1.0.30 — LGPL-2.1-or-later

- Upstream: https://github.com/libusb/libusb
- Source archive: https://github.com/libusb/libusb/releases/download/v1.0.30/libusb-1.0.30.tar.bz2
- SHA-256: fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf
- Covered: bundled libusb-1.0.0.dylib.
- License text: Resources/Licenses/libusb-LGPL-2.1.txt. Copyrights are retained in the source archive.
- The upstream code is unmodified. Packaging changes only the dylib ID. Built from the verified upstream archive for arm64/macOS 14, with --disable-static and --disable-dependency-tracking.

## Library source and replacement

The release app includes both verified upstream archives and rebuild instructions under Contents/Resources/ThirdPartySources. scripts/fetch-third-party-sources.sh checks their SHA-256 before packaging. Both libraries remain separately replaceable dynamic libraries in Contents/Frameworks. See docs/THIRD_PARTY_BUILD.md for rebuilding/replacing them and re-signing your local modified app. Reverse engineering for debugging modifications to the LGPL components is permitted. Do not remove the LGPL licenses, library source archives or this notice from a binary release.

The site's artwork at https://www.appicons.store/ was viewed for general graphic-design inspiration only. No artwork from that store was downloaded, embedded or redistributed.
