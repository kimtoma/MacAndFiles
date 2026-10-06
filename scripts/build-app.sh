#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build-libraries.sh
TASK_MTP_PREFIX="$PWD/.build/libraries/prefix"
TASK_USB_PREFIX="$TASK_MTP_PREFIX"
export LIBRARY_PATH="$TASK_MTP_PREFIX/lib:${LIBRARY_PATH:-}"
scripts/build-icon.sh
swift build -c release
TASK_OUTPUT="$PWD/dist/MacAndFiles.app"
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/maf-build.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT
TASK_APP="$TASK_STAGE/MacAndFiles.app"
mkdir -p "$TASK_APP/Contents/MacOS" "$TASK_APP/Contents/Frameworks" "$TASK_APP/Contents/Resources/Licenses"
clang -Wall -Wextra -Werror -Os -mmacosx-version-min=14.0 Sources/CLILauncher/main.c -o "$TASK_APP/Contents/MacOS/maf"
cp .build/release/MacAndFiles "$TASK_APP/Contents/MacOS/MacAndFiles"
cp "$TASK_MTP_PREFIX/lib/libmtp.9.dylib" "$TASK_APP/Contents/Frameworks/"
cp "$TASK_USB_PREFIX/lib/libusb-1.0.0.dylib" "$TASK_APP/Contents/Frameworks/"
cp Resources/Licenses/* "$TASK_APP/Contents/Resources/Licenses/"
cp LICENSE "$TASK_APP/Contents/Resources/Licenses/MIT.txt"
cp THIRD_PARTY_NOTICES.md "$TASK_APP/Contents/Resources/"
cp Resources/Credits.rtf "$TASK_APP/Contents/Resources/"
for TASK_LOCALIZATION in Sources/MacAndFiles/Resources/*.lproj; do
    ditto --norsrc --noextattr "$TASK_LOCALIZATION" "$TASK_APP/Contents/Resources/$(basename "$TASK_LOCALIZATION")"
done
ditto --norsrc --noextattr dist/third-party-sources "$TASK_APP/Contents/Resources/ThirdPartySources"
cp Resources/Info.plist "$TASK_APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns "$TASK_APP/Contents/Resources/"; fi
install_name_tool -id '@rpath/libmtp.9.dylib' "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
install_name_tool -id '@rpath/libusb-1.0.0.dylib' "$TASK_APP/Contents/Frameworks/libusb-1.0.0.dylib"
TASK_MTP_LINK="$(otool -L .build/release/MacAndFiles | sed -n 's/^[[:space:]]*\(.*\/libmtp\.[^[:space:]]*\) (compatibility version.*$/\1/p')"
TASK_USB_LINK="$(otool -L "$TASK_MTP_PREFIX/lib/libmtp.9.dylib" | sed -n 's/^[[:space:]]*\(.*\/libusb-1\.0[^[:space:]]*\) (compatibility version.*$/\1/p')"
install_name_tool -change "$TASK_MTP_LINK" '@rpath/libmtp.9.dylib' "$TASK_APP/Contents/MacOS/MacAndFiles"
install_name_tool -change "$TASK_USB_LINK" '@rpath/libusb-1.0.0.dylib' "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
install_name_tool -add_rpath '@executable_path/../Frameworks' "$TASK_APP/Contents/MacOS/MacAndFiles"
# New app files can inherit Finder metadata from the workspace; signing forbids it.
/usr/bin/xattr -cr "$TASK_APP"
TASK_IDENTITY="${MAF_SIGN_IDENTITY:--}"
TASK_SIGN_FLAGS=(--force --sign "$TASK_IDENTITY")
if [ "$TASK_IDENTITY" != - ]; then
    case "$TASK_IDENTITY" in 'Developer ID Application:'*) ;; *) echo 'Use a Developer ID Application identity for distribution.' >&2; exit 1 ;; esac
    TASK_SIGN_FLAGS+=(--options runtime --timestamp)
fi
codesign "${TASK_SIGN_FLAGS[@]}" "$TASK_APP/Contents/Frameworks/libusb-1.0.0.dylib"
codesign "${TASK_SIGN_FLAGS[@]}" "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
codesign "${TASK_SIGN_FLAGS[@]}" "$TASK_APP/Contents/MacOS/maf"
codesign "${TASK_SIGN_FLAGS[@]}" "$TASK_APP"
codesign --verify --deep --strict "$TASK_APP"
python3 - "$TASK_APP" <<'PYVERIFY'
import pathlib,subprocess,sys
a=pathlib.Path(sys.argv[1]);paths=[a/'Contents/MacOS/MacAndFiles',a/'Contents/MacOS/maf',*(a/'Contents/Frameworks').glob('*.dylib')]
for path in paths:
    links=subprocess.check_output(['otool','-L',str(path)],text=True).splitlines()[1:]
    dependencies=[line.strip().split(' (compatibility version',1)[0] for line in links]
    assert all(d.startswith(('/System/','/usr/lib/','@rpath/','@executable_path/','@loader_path/')) for d in dependencies),(path.name,dependencies)
PYVERIFY
ditto -c -k --sequesterRsrc --keepParent "$TASK_APP" dist/MacAndFiles-macOS-arm64.zip
# Sign outside iCloud/File Provider folders, which can reattach Finder metadata.
if [ -d "$TASK_OUTPUT" ]; then chmod -R u+w "$TASK_OUTPUT"; fi
ditto --norsrc --noextattr "$TASK_APP" "$TASK_OUTPUT"
/usr/bin/xattr -cr "$TASK_OUTPUT"
codesign --verify --deep --strict "$TASK_OUTPUT"
echo "Built: $TASK_OUTPUT"
