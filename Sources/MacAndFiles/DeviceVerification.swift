import Foundation
import CryptoKit

enum DeviceVerification {
    /// Only modifies a uniquely named test folder; never reads the user's files.
    static func run(roundTrip: Bool) throws -> [String: Any] {
        let mtp = MTPTransport()
        let devices = try mtp.detect()
        guard devices.count == 1, let device = devices.first else {
            throw BridgeError(L10n.text("verification.devices", devices.count))
        }
        let (name, storages) = try mtp.connect(id: device.id)
        defer { mtp.disconnect() }
        guard let storage = storages.first else { throw BridgeError(L10n.text("No storage is available.")) }
        let root = try mtp.list(storage: storage.id, parent: UInt32.max)
        var report: [String: Any] = ["timestamp": ISO8601DateFormatter().string(from: Date()),
            "device": name, "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "storage": storage.name, "storageCapacity": storage.capacity,
            "storageFree": storage.free, "rootItemCount": root.count, "connection": "PASS"]
        guard roundTrip else { return report }
        let local = FileManager.default.temporaryDirectory.appendingPathComponent("AndroidBridge-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: local, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: local) }
        let source = local.appendingPathComponent("source"), destination = local.appendingPathComponent("received")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        let fixtureName = "AndroidBridge-Test-\(UUID().uuidString)"
        let fixture = source.appendingPathComponent(fixtureName)
        let nested = fixture.appendingPathComponent("한글 폴더")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let text = Data("Android Bridge · 갤럭시 폴드7\nUnicode filename and UTF-8 content 검증\n".utf8)
        let binary = Data((0..<(5 * 1024 * 1024)).map { UInt8(truncatingIfNeeded: $0 &* 37 &+ 13) })
        try text.write(to: fixture.appendingPathComponent("한글 문서.txt"))
        try Data().write(to: fixture.appendingPathComponent("empty.bin"))
        try binary.write(to: nested.appendingPathComponent("binary-5MiB.bin"))
        let engine = TransferEngine(transport: mtp, control: TransferControl(), status: { _ in })
        do {
            try engine.upload([fixture], storage: storage.id, parent: UInt32.max)
            guard let remoteFolder = try mtp.list(storage: storage.id, parent: UInt32.max).first(where: { $0.name == fixtureName && $0.isFolder }) else { throw BridgeError(L10n.text("Couldn’t find the test folder.")) }
            try engine.download([remoteFolder], storage: storage.id, to: destination)
            var results: [[String: Any]] = []
            for path in ["한글 문서.txt", "empty.bin", "한글 폴더/binary-5MiB.bin"] {
                let original = try Data(contentsOf: fixture.appendingPathComponent(path))
                let received = try Data(contentsOf: destination.appendingPathComponent(fixtureName).appendingPathComponent(path))
                guard original == received else { throw BridgeError(L10n.text("Round-trip file contents do not match: %@", path)) }
                results.append(["file": path, "bytes": original.count, "sha256": SHA256.hash(data: received).map { String(format: "%02x", $0) }.joined(), "result": "PASS"])
            }
            // Only this freshly created UUID folder is eligible for cleanup.
            try mtp.removeVerificationFolder(remoteFolder, storage: storage.id)
            guard !(try mtp.list(storage: storage.id, parent: UInt32.max)).contains(where: { $0.id == remoteFolder.id }) else { throw BridgeError(L10n.text("Couldn’t confirm test folder cleanup.")) }
            let rootName = "AndroidBridge-Test-file-\(UUID().uuidString).txt"
            let rootFile = source.appendingPathComponent(rootName)
            try text.write(to: rootFile)
            try engine.upload([rootFile], storage: storage.id, parent: UInt32.max)
            guard let uploaded = try mtp.list(storage: storage.id, parent: UInt32.max).first(where: { $0.name == rootName && !$0.isFolder }) else {
                throw BridgeError(L10n.text("Couldn’t find the verification file uploaded to the root: %@", rootName))
            }
            try engine.download([uploaded], storage: storage.id, to: destination)
            guard try Data(contentsOf: destination.appendingPathComponent(rootName)) == text else { throw BridgeError(L10n.text("Root file round-trip mismatch: %@", rootName)) }
            try mtp.removeVerificationFile(uploaded)
            guard !(try mtp.list(storage: storage.id, parent: UInt32.max)).contains(where: { $0.id == uploaded.id }) else { throw BridgeError(L10n.text("Couldn’t clean up the root test file.")) }
            report["rootFileRoundTrip"] = "PASS"
            report["roundTrip"] = "PASS"; report["files"] = results; report["cleanup"] = "PASS"
            return report
        } catch {
            throw BridgeError(L10n.text("%@\nThe test folder “%@” may remain on the device.", error.localizedDescription, fixtureName))
        }
    }
}
