import Foundation

final class FakeDevice: DeviceBackend {
    var connected = false
    var folders: [UInt32: [RemoteItem]] = [:]
    var failID: UInt32?
    var sent = [String]()
    func detect() throws -> [DeviceInfo] { [DeviceInfo(id: "usb:1", name: "Test phone")] }
    func connect(id: String) throws -> (String, [StorageInfo]) {
        guard id == "usb:1" else { throw BridgeError("Missing", code: "device_not_found") }
        connected = true; return ("Test phone", [StorageInfo(id: 1, name: "Internal", capacity: 100, free: 50)])
    }
    func disconnect() { connected = false }
    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem] { folders[parent] ?? [] }
    func receive(_ item: RemoteItem, to: URL, control: TransferControl) throws {
        try Data([7]).write(to: to)
        if failID == item.id { throw BridgeError("USB failed") }
    }
    func send(_ url: URL, storage: UInt32, parent: UInt32, control: TransferControl) throws { sent.append(url.lastPathComponent) }
    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32 { 99 }
}
@main enum CLITests {
    static func main() throws {
        var count = 0
        func test(_ name: String, _ body: () throws -> Void) throws { try body(); count += 1; print("PASS \(name)") }
        func fails(_ code: String, _ body: () throws -> Void) {
            do { try body(); preconditionFailure("Expected \(code)") }
            catch { precondition((error as? BridgeError)?.code == code, "Wrong error: \(error)") }
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("aft-cli-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let device = FakeDevice()
        func item(_ id: UInt32, _ name: String, _ folder: Bool = false) -> RemoteItem { RemoteItem(id: id, name: name, size: 1, isFolder: folder, modified: Date()) }
        let base = ["--device", "usb:1", "--storage", "1"]
        try test("Arguments reject missing/unknown/duplicate/overflow before USB") {
            for args in [["wat"], ["ls"], ["devices", "--device", "x"], ["ls"] + base + ["--storage", "1"], ["ls", "--device", "usb:1", "--storage", "4294967296"], ["upload"] + base + ["--from", "x"]] { fails("invalid_arguments") { _ = try CLIRequest(args) } }
            precondition(!device.connected)
        }
        try test("Absolute paths reject traversal and invalid names") {
            for path in ["relative", "/../secret", "/bad:name", "/bad\0name"] { fails("invalid_path") { _ = try RemotePath.components(path) } }
        }
        try test("Hex storage IDs and repeated upload sources") {
            let r = try CLIRequest(["upload", "--device", "usb:1", "--storage", "0x10001", "--from", "a", "--from", "b", "--to", "/"])
            let storage = try r.storageID(); precondition(storage == 65537); precondition(r.options["from"] == ["a", "b"])
        }
        try test("Help and devices do not claim USB") {
            let executor = CLIExecutor(backend: device)
            _ = try executor.run(CLIRequest([])); _ = try executor.run(CLIRequest(["devices"]))
            precondition(!device.connected)
        }
        try test("Storages and root listing release USB") {
            device.folders[UInt32.max] = [item(10, "한글 폴더", true)]
            let result = try CLIExecutor(backend: device).run(CLIRequest(["ls"] + base))
            precondition((result["items"] as? [[String: Any]])?.count == 1); precondition(!device.connected)
        }
        try test("Unknown device and storage fail deterministically") {
            fails("device_not_found") { _ = try CLIExecutor(backend: device).run(CLIRequest(["storages", "--device", "wrong"])) }
            fails("storage_not_found") { _ = try CLIExecutor(backend: device).run(CLIRequest(["ls", "--device", "usb:1", "--storage", "2"])) }
            precondition(!device.connected)
        }
        try test("Nested Unicode paths resolve to the exact object") {
            device.folders[10] = [item(11, "한글 문서.txt")]
            let resolved = try RemotePath.resolve("/한글 폴더/한글 문서.txt", storage: 1, backend: device)
            precondition(resolved?.id == 11)
        }
        try test("Duplicate names and files as parent folders are rejected") {
            device.folders[10] = [item(11, "same"), item(12, "same")]
            fails("ambiguous_path") { _ = try RemotePath.resolve("/한글 폴더/same", storage: 1, backend: device) }
            device.folders[10] = [item(11, "file")]
            fails("not_a_directory") { _ = try RemotePath.resolve("/한글 폴더/file/child", storage: 1, backend: device) }
        }
        try test("Mkdir collision never mutates the device") {
            let executor = CLIExecutor(backend: device)
            fails("already_exists") { _ = try executor.run(CLIRequest(["mkdir"] + base + ["--path", "/한글 폴더"])) }
            precondition(!executor.mutationAttempted && !device.connected)
        }
        try test("Successful download publishes Unicode bytes and a receipt") {
            device.folders[10] = [item(11, "한글 문서.txt")]
            let executor = CLIExecutor(backend: device)
            _ = try executor.run(CLIRequest(["download"] + base + ["--path", "/한글 폴더/한글 문서.txt", "--to", root.path]))
            let bytes = try Data(contentsOf: root.appendingPathComponent("한글 문서.txt")); precondition(bytes == Data([7]))
            precondition(executor.completed.count == 1 && !device.connected)
        }
        try test("Partial folder download reports published entries and cleans temporary bytes") {
            device.folders[10] = [item(21, "first"), item(22, "failure")]; device.failID = 22
            let executor = CLIExecutor(backend: device)
            fails("transfer_failed") { _ = try executor.run(CLIRequest(["download"] + base + ["--path", "/한글 폴더", "--to", root.path])) }
            precondition(executor.completed.count == 2) // Created folder + first complete file.
            let children = try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("한글 폴더").path); precondition(children == ["first"])
            precondition(!device.connected); device.failID = nil
        }
        try test("Upload reuses the shared engine and reports its parent ID") {
            let executor = CLIExecutor(backend: device)
            _ = try executor.run(CLIRequest(["upload"] + base + ["--from", root.appendingPathComponent("한글 문서.txt").path, "--to", "/"]))
            precondition(device.sent == ["한글 문서.txt"]); precondition(executor.completed.count == 1); precondition(executor.completed[0]["parentID"] as? UInt32 == UInt32.max); precondition(executor.completed[0]["objectID"] == nil)
        }
        try test("Cancellation preserves existing data and releases the session") {
            let control = TransferControl(); control.cancel()
            fails("cancelled") { _ = try CLIExecutor(backend: device, control: control).run(CLIRequest(["ls"] + base)) }
            precondition(!device.connected); precondition(CLIExecutor.exitCode(BridgeError("Canceled", code: "cancelled")) == 130)
        }
        try test("USB lock contention and release") {
            var first: DeviceAccess? = try DeviceAccess(id: "test", directory: root)
            withExtendedLifetime(first) { fails("device_busy") { _ = try DeviceAccess(id: "test", directory: root) } }
            first = nil
            let second = try DeviceAccess(id: "test", directory: root)
            withExtendedLifetime(second) {}
        }
        print("\(count) CLI tests passed")
    }
}
