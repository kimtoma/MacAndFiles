#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${MAF_SIGN_IDENTITY:?Set MAF_SIGN_IDENTITY to your Developer ID Application certificate name.}"
: "${MAF_NOTARY_PROFILE:?Set MAF_NOTARY_PROFILE to an existing notarytool keychain profile.}"
case "$MAF_SIGN_IDENTITY" in 'Developer ID Application:'*) ;; *) echo 'Developer ID Application is required.' >&2; exit 1 ;; esac
scripts/build-app.sh
xcrun notarytool submit dist/MacAndFiles-macOS-arm64.zip --keychain-profile "$MAF_NOTARY_PROFILE" --wait --output-format json > dist/notarization.json
python3 - <<'PY'
import json
from pathlib import Path
result=json.loads(Path('dist/notarization.json').read_text())
if result.get('status') != 'Accepted':
    raise SystemExit('Notarization was not accepted. Inspect dist/notarization.json and the notarytool log; no stapled release was produced.')
PY
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/maf-notarized.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT
ditto -x -k dist/MacAndFiles-macOS-arm64.zip "$TASK_STAGE"
xcrun stapler staple "$TASK_STAGE/MacAndFiles.app"
xcrun stapler validate "$TASK_STAGE/MacAndFiles.app"
codesign --verify --deep --strict "$TASK_STAGE/MacAndFiles.app"
spctl --assess --type execute --verbose=2 "$TASK_STAGE/MacAndFiles.app"
ditto -c -k --sequesterRsrc --keepParent "$TASK_STAGE/MacAndFiles.app" dist/MacAndFiles-macOS-arm64.zip
ditto --norsrc --noextattr "$TASK_STAGE/MacAndFiles.app" dist/MacAndFiles.app
echo 'Notarization accepted and stapled. Test a downloaded quarantined copy on another Mac before declaring public distribution verified.'
