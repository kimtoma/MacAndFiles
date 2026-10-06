// swift-tools-version: 5.9
import PackageDescription
import Foundation

let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(".build/libraries/prefix/lib").path

let package = Package(
    name: "MacAndFiles",
    defaultLocalization: "en",
    platforms: [.macOS("14.0")],
    products: [.executable(name: "MacAndFiles", targets: ["MacAndFiles"])],
    targets: [
        .systemLibrary(name: "CLibMTP"),
        .executableTarget(name: "MacAndFiles", dependencies: ["CLibMTP"],
            resources: [.process("Resources")],
            linkerSettings: [.unsafeFlags(["-L" + libraryPath, "-L/opt/homebrew/lib", "-L/usr/local/lib"])])
    ]
)
