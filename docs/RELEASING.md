# Preparing a public release

## Local release files

```sh
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
python3 scripts/test-site.py
scripts/build-app.sh
scripts/package-source.sh
```

Outputs: dist/MacAndFiles-macOS-arm64.zip and dist/MacAndFiles-source.tar.gz. The app ZIP includes project MIT text, third-party notices, Android CC BY text, LGPL texts, corresponding library source archives and rebuild instructions. The source archive includes code, icon master, guides and notices, without build directories, Git metadata or private device diagnostics.

Verify an extracted ZIP in a non-synced directory with codesign --verify --deep --strict. Check @rpath dependencies with otool -L. Run the bundled --diagnose command, then visually launch the app and verify the selected icon. For transfer code changes, run fixture-based hardware verification on the designated device as well. Record which checks actually ran and which platforms/devices remain unverified.

## Before publishing to GitHub

1. The chosen application name is "MacAndFiles" (formerly "Android File Transfer" and "Android Bridge"). Keep bundle display name, UI, CLI metadata, README and release filenames consistent. This independent project has no Google affiliation or brand approval. Review the trademark guidance in THIRD_PARTY_NOTICES.md before public distribution. Preserve a legacy Google installation under a distinct name rather than deleting it.
2. Keep LICENSE and THIRD_PARTY_NOTICES.md together. Advertise the project's code as MIT, with LGPL libraries and CC BY robot artwork exceptions.
3. Inspect source contents for private paths, tokens, raw device listings or screenshots. Release packaging excludes dist/, .build/, .git/ and editor metadata.
4. Publish the matching source archive next to the app ZIP, or ensure the complete matching repository version is accessible alongside it. The LGPL upstream sources are already bundled within the app ZIP.
5. Ad-hoc-signed apps are for local development. For a normal public macOS download, use your Apple Developer ID certificate to sign inner libraries and the app, notarize with your credentials, staple, and test a downloaded quarantined copy on another Mac. The automated signing/notarization path is configured below. A certificate and credentials must be supplied by the maintainer; do not describe a build as notarized unless the submission is Accepted, stapling validates and a real downloaded copy passes.
6. Publish checksums, release notes, exact minimum OS/architecture and tested-device scope. Do not claim macOS 28, Intel or untested devices are verified.

Creating a local release artifact does not publish a GitHub repository or release. Upload only to the repository/account selected by the maintainer.

## Developer ID and notarization

Use an installed **Developer ID Application** certificate (an Apple Development certificate is insufficient). Configure a `notarytool` keychain profile outside this repository. Never commit credentials.

```sh
export MAF_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
export MAF_NOTARY_PROFILE="YOUR_EXISTING_KEYCHAIN_PROFILE"
scripts/notarize-app.sh
```

The build signs libraries and the native launcher before the app, with hardened runtime and timestamping. The notarization script requires Accepted, staples, validates, assesses and repackages. Default builds remain ad-hoc signed.

## Hardware stress verification

With an explicitly authorized device unlocked in File Transfer mode, disconnect the GUI and run:

```sh
python3 scripts/test-hardware.py --device DEVICE_ID --storage STORAGE_ID --keep-fixture
```

This uses a disposable UUID folder, a 4 GiB + 1 MiB file, 2,000 small files and real cancellation. `--case cable --fixture UUID_FOLDER` requires physically unplugging during an observed stream. Reconnect, rediscover its device ID and use `--case cleanup --fixture UUID_FOLDER` to remove only the allowlisted fixture tree. Logs are ignored under dist/hardware. Never report timed-out or unperformed cases as passing.
