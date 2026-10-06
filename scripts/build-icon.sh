#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_ICON_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/androidbridge-icon.XXXXXX")"
trap 'rm -rf "$TASK_ICON_STAGE"' EXIT
swift scripts/make-icon.swift Resources/Icon/AppIcon-master.png "$TASK_ICON_STAGE/AppIcon.iconset"
iconutil -c icns "$TASK_ICON_STAGE/AppIcon.iconset" -o Resources/AppIcon.icns
echo "Updated Resources/AppIcon.icns"
