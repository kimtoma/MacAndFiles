#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_TEST_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/androidbridge-l10n-tests.XXXXXX")"
trap 'rm -rf "$TASK_TEST_STAGE"' EXIT
TASK_TEST_APP="$TASK_TEST_STAGE/LocalizationTests.app"
mkdir -p "$TASK_TEST_APP/Contents/MacOS" "$TASK_TEST_APP/Contents/Resources"
cp -R Sources/MacAndFiles/Resources/*.lproj "$TASK_TEST_APP/Contents/Resources/"
cat > "$TASK_TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>LocalizationTests</string>
<key>CFBundleIdentifier</key><string>local.androidbridge.localizationtests</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
</dict></plist>
PLIST
swiftc Sources/MacAndFiles/Localization.swift Tests/LocalizationTests.swift -o "$TASK_TEST_APP/Contents/MacOS/LocalizationTests"
for TASK_LANGUAGE in en ko zh-Hans zh-Hant es pt-BR ja de fr ru hi id ar; do
    "$TASK_TEST_APP/Contents/MacOS/LocalizationTests" "$TASK_LANGUAGE" -AppleLanguages "($TASK_LANGUAGE)"
done
# An unsupported language resolves to the English development region.
"$TASK_TEST_APP/Contents/MacOS/LocalizationTests" en -AppleLanguages '(zz)'
# Foundation resolves region/script variants without an app-owned language picker.
"$TASK_TEST_APP/Contents/MacOS/LocalizationTests" zh-Hans -AppleLanguages '(zh-CN)'
"$TASK_TEST_APP/Contents/MacOS/LocalizationTests" zh-Hant -AppleLanguages '(zh-TW)'
"$TASK_TEST_APP/Contents/MacOS/LocalizationTests" es -AppleLanguages '(es-MX)'
