# Localization and translation

English is the development language and source README. The application ships 13 localizations: `en`, `ko`, `zh-Hans`, `zh-Hant`, `es`, `pt-BR`, `ja`, `de`, `fr`, `ru`, `hi`, `id`, and `ar`.

## Native macOS behavior

The app uses Foundation bundle localization, UTF-8 `.strings` tables and `.stringsdict` plural rules. `CFBundleDevelopmentRegion` is `en`. macOS chooses resources using the user's preferred languages or per-app language setting, with English as the development fallback. Relaunch after changing a language in System Settings → General → Language & Region → Applications. There is no app-owned language setting and production code never changes AppleLanguages.

Date formatting, ByteCountFormatter and percentage FormatStyle use regional settings. UI translation and regional formatting are separate: an English interface can still use another region's dates and number conventions. SwiftUI follows the native layout direction, including Arabic. Do not translate device-provided names or file names. Preserve the Korean Unicode verification fixtures and their bytes. Underlying libmtp error details can remain in upstream English; our explanatory context is localized.

See Apple's [localization guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html) and [localized package resources](https://developer.apple.com/documentation/xcode/localizing-package-resources).

## Editing translations

- `Sources/MacAndFiles/Localization.swift`: shared lookup/format helper for SwiftUI, AppKit and transport errors. Packaged apps use their main bundle; SwiftPM development execution uses Bundle.module.
- `Sources/MacAndFiles/Resources/<language>.lproj/Localizable.strings`: app-owned labels, menus, dialogs, help and errors. English source phrases are keys; `help.usb` is a long-form help key.
- `Localizable.stringsdict`: nine count messages. Keep native `NSStringPluralRuleType`, value type `ld`, and each language's `other` form. Russian adds `one/few/many`; Arabic adds `zero/one/two/few/many`.
- `docs/readme/README.<language>.md`: translated usage/build/safety/license documentation. English README.md is the full technical reference. Korean retains the earlier detailed guide; other translations cover the same essential operating and release constraints.

Use `L10n.text("English source text")` for app-owned runtime strings. Format messages as whole sentences with placeholders, never by joining translated fragments. Preserve `%@` and `%ld` argument types; use positional placeholders if a language needs reordered arguments. Percent signs in file names are data, not format instructions. `.strings` syntax requires escaping quotes, backslashes and newlines.

For a new language, copy English tables into an ISO language/script/region `.lproj` folder, translate all keys and plural variants, add a README and update every language navigation row. Update the supported-language test list and documentation. The build script copies all `.lproj` resources into the native app before signing; SwiftPM processes the same resources with defaultLocalization en. No Xcode string-catalog compiler or translation service is required.

## Verification

```sh
scripts/test-localization.sh
scripts/test.sh
scripts/build-app.sh
```

The localization test creates an isolated temporary app bundle and uses process-only AppleLanguages arguments; it does not change the user's settings. It checks native preferred-localization matching, unsupported-language fallback, regional Chinese/Spanish matching, all substitutions and counts 0, 1, 2, 5, 11, 21, 101. English and Russian inflections and Arabic zero/dual have explicit assertions.

Review localized UI with long text, small windows, file panels, errors and both layout directions. Synthetic previews validate appearance only; separately verify the installed app and device browsing. Automated structural/runtime checks do not replace fluent-speaker translation review. Contributions improving idiom or platform terminology are welcome; keep transfer and licensing meaning intact.
