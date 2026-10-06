import Foundation

@main
enum LocalizationTests {
    static func main() throws {
        let expected = CommandLine.arguments[1]
        precondition(Bundle.main.preferredLocalizations.first == expected, "Unexpected native language: \(Bundle.main.preferredLocalizations)")
        precondition(L10n.bundle.bundleURL == Bundle.main.bundleURL)
        precondition(L10n.isRightToLeft == (expected == "ar"))
        let languageBundle = Bundle(path: Bundle.main.path(forResource: expected, ofType: "lproj")!)!
        let strings = try PropertyListSerialization.propertyList(from: Data(contentsOf: languageBundle.url(forResource: "Localizable", withExtension: "strings")!), format: nil) as! [String: String]
        precondition(L10n.text("Storage") == strings["Storage"], "Main-bundle lookup selected the wrong language")
        let placeholders = try NSRegularExpression(pattern: "%((\\d+)\\$)?(@|ld)")
        for (key, value) in strings {
            precondition(!value.isEmpty)
            func types(_ text: String) -> [String] {
                placeholders.matches(in: text, range: NSRange(text.startIndex..., in: text)).map {
                    String(text[Range($0.range(at: 3), in: text)!])
                }.sorted()
            }
            precondition(types(key) == types(value), "Mismatched placeholders: \(expected) \(key)")
            let arguments: [CVarArg] = key.contains("%ld") ? [Int(7)] : Array(repeating: "文서%файл.txt", count: key.components(separatedBy: "%@").count - 1)
            let result = L10n.format(key, arguments: arguments, bundle: languageBundle, locale: Locale(identifier: expected))
            precondition(!result.contains("%@") && !result.contains("%ld"), "Unexpanded format: \(key)")
            if !arguments.isEmpty && !key.contains("%ld") { precondition(result.contains("文서%файл.txt")) }
        }
        let pluralKeys = ["search.results", "selection.count", "devices.detected", "items.ready", "upload.started", "upload.completed", "download.started", "download.completed", "verification.devices"]
        for key in pluralKeys {
            for n in [0, 1, 2, 5, 11, 21, 101] {
                let result = L10n.text(key, n)
                precondition(result != key && !result.contains("%#@") && !result.contains("%ld"), "Invalid plural: \(expected) \(key) \(result)")
                if key == "search.results" { print("\(expected) \(n): \(result)") }
            }
        }
        if expected == "en" {
            precondition(L10n.text("search.results", 1) == "1 result")
            precondition(L10n.text("search.results", 2) == "2 results")
        }
        if expected == "ru" {
            precondition(L10n.text("search.results", 1) == "1 результат")
            precondition(L10n.text("search.results", 2) == "2 результата")
            precondition(L10n.text("search.results", 5) == "5 результатов")
            precondition(L10n.text("search.results", 21) == "21 результат")
        }
        if expected == "ar" {
            precondition(L10n.text("search.results", 0).contains("لا توجد نتائج"))
            precondition(L10n.text("search.results", 2).contains("نتيجتان"))
        }
        print("PASS \(expected): native language, strings, safe substitutions and plural rules")
    }
}
