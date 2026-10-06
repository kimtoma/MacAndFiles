import Foundation

/// Foundation resolves the user's system or per-app language; do not override AppleLanguages.
enum L10n {
    static var bundle: Bundle {
        if Bundle.main.url(forResource: "Localizable", withExtension: "strings") != nil {
            return .main
        }
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments: arguments, bundle: bundle, locale: .current)
    }

    static var isRightToLeft: Bool {
        Locale.Language(identifier: bundle.preferredLocalizations.first ?? "en").characterDirection == .rightToLeft
    }

    static func format(_ key: String, arguments: [CVarArg], bundle: Bundle, locale: Locale) -> String {
        let template = bundle.localizedString(forKey: key, value: key, table: nil)
        return arguments.isEmpty ? template : String(format: template, locale: locale, arguments: arguments)
    }
}
