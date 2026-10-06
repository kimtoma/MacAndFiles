import Foundation

/// Installs per-user aliases only after preflighting both names. No shell profile edits.
enum CLIInstallation {
    static func isInstalled(app: URL = Bundle.main.bundleURL, bin: URL? = nil) -> Bool {
        let directory = bin ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin")
        let target = app.appendingPathComponent("Contents/MacOS/maf").path
        return (try? FileManager.default.destinationOfSymbolicLink(atPath: directory.appendingPathComponent("maf").path)) == target
    }
    static func install(app: URL = Bundle.main.bundleURL, bin: URL? = nil) throws {
        let fm = FileManager.default
        let directory = bin ?? fm.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin")
        let target = app.appendingPathComponent("Contents/MacOS/maf").path
        guard fm.isExecutableFile(atPath: target) else { throw BridgeError(L10n.text("The bundled CLI is unavailable. Install the packaged app.")) }
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in ["maf", "aft"] {
            let path = directory.appendingPathComponent(name).path
            let existing = try? fm.destinationOfSymbolicLink(atPath: path)
            if existing == target { continue }
            if name == "aft", existing == "/Applications/Android File Transfer.app/Contents/MacOS/aft" {
                let old = URL(fileURLWithPath: "/Applications/Android File Transfer.app")
                if !fm.fileExists(atPath: old.path) { continue }
                if let bundle = Bundle(url: old), bundle.bundleIdentifier == "local.androidbridge.mac" { continue }
            }
            if fm.fileExists(atPath: path) || existing != nil {
                throw BridgeError(L10n.text("Another command already uses %@. Nothing was replaced.", name), code: "already_exists")
            }
        }
        for name in ["maf", "aft"] {
            let path = directory.appendingPathComponent(name).path
            if (try? fm.destinationOfSymbolicLink(atPath: path)) == target { continue }
            if (try? fm.destinationOfSymbolicLink(atPath: path)) != nil { try fm.removeItem(atPath: path) }
            try fm.createSymbolicLink(atPath: path, withDestinationPath: target)
        }
    }
}
