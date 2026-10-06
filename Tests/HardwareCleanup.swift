import Foundation

@main enum HardwareCleanup {
    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count == 3, let storage = UInt32(args[1]), args[2].hasPrefix("AndroidBridge-Test-"),
              UUID(uuidString: String(args[2].dropFirst("AndroidBridge-Test-".count))) != nil else { throw BridgeError("Usage: cleanup DEVICE_ID STORAGE_ID UUID_FIXTURE_NAME") }
        let backend = MTPTransport()
        let (_, storages) = try backend.connect(id: args[0]); defer { backend.disconnect() }
        guard storages.contains(where: { $0.id == storage }) else { throw BridgeError("Storage does not belong to this device") }
        let matches = try backend.list(storage: storage, parent: UInt32.max).filter { $0.name == args[2] }
        guard matches.count == 1 else { throw BridgeError("Fixture is missing or ambiguous; no cleanup attempted") }
        try backend.removeStressVerificationFolder(matches[0], storage: storage)
        guard !(try backend.list(storage: storage, parent: UInt32.max)).contains(where: { $0.name == args[2] }) else { throw BridgeError("Fixture cleanup could not be confirmed") }
        print("PASS fixture cleanup confirmed")
    }
}
