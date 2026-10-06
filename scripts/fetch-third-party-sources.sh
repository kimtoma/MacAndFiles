#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_SOURCE_DIR="$PWD/dist/third-party-sources"
mkdir -p "$TASK_SOURCE_DIR"
fetch_source() {
    local task_name="$1" task_url="$2" task_sha="$3"
    if [ ! -f "$TASK_SOURCE_DIR/$task_name" ]; then
        curl --fail --location --retry 2 --connect-timeout 20 "$task_url" -o "$TASK_SOURCE_DIR/$task_name"
    fi
    printf '%s  %s\n' "$task_sha" "$TASK_SOURCE_DIR/$task_name" | shasum -a 256 -c -
}
fetch_source libmtp-1.1.23.tar.gz https://downloads.sourceforge.net/project/libmtp/libmtp/1.1.23/libmtp-1.1.23.tar.gz 74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed
fetch_source libusb-1.0.30.tar.bz2 https://github.com/libusb/libusb/releases/download/v1.0.30/libusb-1.0.30.tar.bz2 fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf
cp docs/THIRD_PARTY_BUILD.md "$TASK_SOURCE_DIR/README.md"
