#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/fetch-third-party-sources.sh
TASK_OUTPUT="$PWD/.build/libraries/prefix"
TASK_CACHE="$PWD/.build/libraries"
TASK_TARGET=14.0
TASK_MARKER="$TASK_OUTPUT/.manifest"
TASK_MANIFEST='libmtp=1.1.23 libusb=1.0.30 arch=arm64 min=14.0 revision=2'
if [ -f "$TASK_MARKER" ] && [ "$(cat "$TASK_MARKER")" = "$TASK_MANIFEST" ] && [ -f "$TASK_OUTPUT/lib/libmtp.9.dylib" ] && [ -f "$TASK_OUTPUT/lib/libusb-1.0.0.dylib" ]; then exit 0; fi
mkdir -p "$TASK_CACHE"
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/maf-libraries.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT
TASK_PREFIX="$TASK_STAGE/prefix"
TASK_SDK="$(xcrun --sdk macosx --show-sdk-path)"
export MACOSX_DEPLOYMENT_TARGET="$TASK_TARGET"
export CFLAGS="-O2 -arch arm64 -isysroot $TASK_SDK -mmacosx-version-min=$TASK_TARGET"
export LDFLAGS="-arch arm64 -isysroot $TASK_SDK -mmacosx-version-min=$TASK_TARGET"
tar -xf dist/third-party-sources/libusb-1.0.30.tar.bz2 -C "$TASK_STAGE"
tar -xf dist/third-party-sources/libmtp-1.1.23.tar.gz -C "$TASK_STAGE"
(cd "$TASK_STAGE/libusb-1.0.30"; ./configure --prefix="$TASK_PREFIX" --disable-static --disable-dependency-tracking; make -j4; make install)
export PKG_CONFIG_LIBDIR="$TASK_PREFIX/lib/pkgconfig"
export CPPFLAGS="-I$TASK_PREFIX/include"
export LDFLAGS="$LDFLAGS -L$TASK_PREFIX/lib"
(cd "$TASK_STAGE/libmtp-1.1.23"; ./configure --prefix="$TASK_PREFIX" --disable-static --disable-mtpz --disable-dependency-tracking --disable-silent-rules; make -j4; make install)
mkdir -p "$TASK_OUTPUT"
ditto --norsrc --noextattr "$TASK_PREFIX" "$TASK_OUTPUT"
install_name_tool -id "$TASK_OUTPUT/lib/libusb-1.0.0.dylib" "$TASK_OUTPUT/lib/libusb-1.0.0.dylib"
install_name_tool -id "$TASK_OUTPUT/lib/libmtp.9.dylib" "$TASK_OUTPUT/lib/libmtp.9.dylib"
TASK_USB_LINK="$(otool -L "$TASK_OUTPUT/lib/libmtp.9.dylib" | awk '/\/libusb-1.0/ {print $1}')"
install_name_tool -change "$TASK_USB_LINK" "$TASK_OUTPUT/lib/libusb-1.0.0.dylib" "$TASK_OUTPUT/lib/libmtp.9.dylib"
codesign --force --sign - "$TASK_OUTPUT/lib/libusb-1.0.0.dylib"
codesign --force --sign - "$TASK_OUTPUT/lib/libmtp.9.dylib"
printf '%s\n'  "$TASK_MANIFEST" > "$TASK_MARKER"
echo "Built pinned arm64 libraries for macOS $TASK_TARGET"
