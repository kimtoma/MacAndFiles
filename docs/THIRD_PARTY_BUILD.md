# Rebuilding and replacing the LGPL libraries

The release bundles unmodified libmtp 1.1.23 and libusb 1.0.30 sources alongside their dynamically linked binaries. See THIRD_PARTY_NOTICES.md for exact archive URLs, hashes and license scope. scripts/build-libraries.sh builds the verified archives with no upstream source patches, targeting arm64/macOS 14. The build prefix and resulting install names are adapted during app packaging.

To rebuild on Apple Silicon macOS with Command Line Tools and make installed, extract the archives from Contents/Resources/ThirdPartySources into a new working directory. Then run:

```sh
export TASK_LIB_PREFIX="$PWD/local-libs"
tar -xjf libusb-1.0.30.tar.bz2
(cd libusb-1.0.30 && ./configure --prefix="$TASK_LIB_PREFIX" --disable-dependency-tracking && make && make install)
tar -xzf libmtp-1.1.23.tar.gz
export PKG_CONFIG_PATH="$TASK_LIB_PREFIX/lib/pkgconfig"
export CPPFLAGS="-I$TASK_LIB_PREFIX/include"
export LDFLAGS="-L$TASK_LIB_PREFIX/lib"
(cd libmtp-1.1.23 && ./configure --prefix="$TASK_LIB_PREFIX" --disable-mtpz --disable-silent-rules --with-udev="$TASK_LIB_PREFIX/lib/udev" && make && make install)
```

libmtp also requires pkg-config (`brew install pkgconf`). You may modify either library under its LGPL terms. Keep ABI-compatible dylib names and exported symbols, or rebuild the MIT application against your changed API.

To use your own libraries, copy the app to a writable, non-synced local directory and replace its Frameworks dylibs. Example (adjust TASK_APP to your copied app):

```sh
export TASK_APP="$PWD/MacAndFiles.app"
chmod -R u+w "$TASK_APP"
cp "$TASK_LIB_PREFIX/lib/libusb-1.0.0.dylib" "$TASK_APP/Contents/Frameworks/"
cp "$TASK_LIB_PREFIX/lib/libmtp.9.dylib" "$TASK_APP/Contents/Frameworks/"
install_name_tool -id '@rpath/libusb-1.0.0.dylib' "$TASK_APP/Contents/Frameworks/libusb-1.0.0.dylib"
install_name_tool -id '@rpath/libmtp.9.dylib' "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
otool -L "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
```

Use `install_name_tool -change` to replace the displayed absolute libusb path in libmtp with `@rpath/libusb-1.0.0.dylib`. The app executable already loads libmtp through @rpath and has @executable_path/../Frameworks in its rpath. Re-sign the modified binaries before launching:

```sh
/usr/bin/xattr -cr "$TASK_APP"
codesign --force --sign - "$TASK_APP/Contents/Frameworks/libusb-1.0.0.dylib"
codesign --force --sign - "$TASK_APP/Contents/Frameworks/libmtp.9.dylib"
codesign --force --sign - "$TASK_APP"
codesign --verify --deep --strict "$TASK_APP"
```

The project imposes no restriction on reverse engineering to debug your LGPL library modifications. Public redistribution of a changed library must include its corresponding modified source, build information and LGPL notices. Update the source manifest/hashes and release bundle to match the binaries you actually distribute.

## Reproducible deployment target

Install Command Line Tools with a macOS 26+ SDK and `brew install pkg-config`. Run `scripts/build-libraries.sh`; it verifies archives, sets `MACOSX_DEPLOYMENT_TARGET=14.0`, and builds into a temporary directory outside synced workspaces. Its cache is `.build/libraries/prefix`. Delete only that generated cache to force a rebuild. Then run `scripts/build-app.sh` to bundle the rebuilt libraries, rewrite load paths and sign. Do not use Homebrew library binaries built for a newer minimum OS.
