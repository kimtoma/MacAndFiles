#!/bin/bash
set -euo pipefail
TASK_APP="${1:-/Applications/MacAndFiles.app}"
TASK_BIN="${2:-$HOME/.local/bin}"
if [ ! -x "$TASK_APP/Contents/MacOS/maf" ]; then
    echo "Missing bundled CLI: $TASK_APP/Contents/MacOS/maf" >&2; exit 1
fi
TASK_APP="$(cd "$TASK_APP" && pwd -P)"
TASK_LAUNCHER="$TASK_APP/Contents/MacOS/maf"
mkdir -p "$TASK_BIN"
# Preflight both names so a conflict cannot cause a partial installation.
for TASK_NAME in maf aft; do
    TASK_COMMAND="$TASK_BIN/$TASK_NAME"
    if [ -e "$TASK_COMMAND" ] || [ -L "$TASK_COMMAND" ]; then
        TASK_EXISTING=""
        if [ -L "$TASK_COMMAND" ]; then TASK_EXISTING="$(readlink "$TASK_COMMAND")"; fi
        if [ "$TASK_EXISTING" != "$TASK_LAUNCHER" ]; then
            # Only migrate our known previous installation, not arbitrary aft tools.
            if [ "$TASK_NAME" != aft ] || [ "$TASK_EXISTING" != '/Applications/Android File Transfer.app/Contents/MacOS/aft' ]; then
                echo "Refusing to overwrite another $TASK_NAME command: $TASK_COMMAND" >&2; exit 1
            fi
            TASK_OLD_APP='/Applications/Android File Transfer.app'
            if [ -d "$TASK_OLD_APP" ] && [ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$TASK_OLD_APP/Contents/Info.plist" 2>/dev/null || true)" != 'local.androidbridge.mac' ]; then
                echo "Refusing to migrate an unrelated aft bundle: $TASK_OLD_APP" >&2; exit 1
            fi
        fi
    fi
done
for TASK_NAME in maf aft; do
    ln -sfn "$TASK_LAUNCHER" "$TASK_BIN/$TASK_NAME"
    echo "Installed: $TASK_BIN/$TASK_NAME"
done
case ":$PATH:" in *":$TASK_BIN:"*) ;; *) echo "Add $TASK_BIN to PATH, or invoke $TASK_BIN/maf directly." ;; esac
