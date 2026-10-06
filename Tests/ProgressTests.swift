import Foundation
import Darwin

final class ProgressBackend: FileTransport {
    var items: [RemoteItem] = []
    var failID: UInt32?
    var cancelOnReceive = false
    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem] { items }
    func receive(_ item: RemoteItem, to url: URL, control: TransferControl) throws {
        let fd = open(url.path, O_CREAT | O_EXCL | O_WRONLY, 0o600)
        guard fd >= 0 else { throw BridgeError("create failed") }
        defer { close(fd) }
        guard ftruncate(fd, off_t(item.size)) == 0 else { throw BridgeError("truncate failed") }
        control.report(0.5)
        if cancelOnReceive { control.cancel(); try control.check() }
        if failID == item.id { throw BridgeError("USB disconnected") }
        control.report(1)
    }
    func send(_ url: URL, storage: UInt32, parent: UInt32, control: TransferControl) throws { control.report(1) }
    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32 { 100 }
}

@main enum ProgressTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        func item(_ id: UInt32, _ size: UInt64) -> RemoteItem { RemoteItem(id: id, name: "\(id).bin", size: size, isFolder: false, modified: Date()) }
        func folder(_ name: String) throws -> URL { let url = root.appendingPathComponent(name); try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false); return url }
        let backend = ProgressBackend()
        // This is a sparse local test of >UInt32 accounting, not physical USB evidence.
        let huge = UInt64(4) * 1024 * 1024 * 1024 + 1
        let control = TransferControl()
        try TransferEngine(transport: backend, control: control, status: { _ in }).download([item(1, huge), item(2, 0)], storage: 1, to: folder("large"))
        precondition(control.snapshot.totalBytes == huge && control.snapshot.transferredBytes == huge)
        precondition(control.snapshot.totalFiles == 2 && control.snapshot.completedFiles == 2 && control.snapshot.finished)
        precondition(control.snapshot.fraction == 1)
        print("PASS >4GiB UInt64 accounting and zero-byte completion")
        let partial = TransferControl(); backend.failID = 4
        do { try TransferEngine(transport: backend, control: partial, status: { _ in }).download([item(3, 10), item(4, 20), item(5, 30)], storage: 1, to: folder("partial")); preconditionFailure("Expected failure") } catch {}
        precondition(partial.snapshot.completedFiles == 1 && partial.snapshot.totalFiles == 3 && !partial.snapshot.finished)
        precondition(partial.snapshot.failures.count == 1 && partial.snapshot.failures[0].item.hasSuffix("4.bin"))
        precondition(partial.snapshot.fraction < 1)
        print("PASS failed item, preserved count and incomplete overall progress")
        let cancelled = TransferControl(); backend.failID = nil; backend.cancelOnReceive = true
        let target = try folder("cancel")
        do { try TransferEngine(transport: backend, control: cancelled, status: { _ in }).download([item(6, 4)], storage: 1, to: target); preconditionFailure("Expected cancellation") } catch {}
        precondition(cancelled.snapshot.completedFiles == 0 && cancelled.snapshot.failures[0].code == "cancelled")
        let remaining = try FileManager.default.contentsOfDirectory(atPath: target.path)
        precondition(remaining.isEmpty)
        print("PASS cancelled bytes never count as a completed file and temporary data is cleaned")
        let many = TransferControl(); backend.cancelOnReceive = false
        try TransferEngine(transport: backend, control: many, status: { _ in }).download((1...2000).map { item(UInt32($0), 0) }, storage: 1, to: folder("many"))
        precondition(many.snapshot.totalFiles == 2000 && many.snapshot.completedFiles == 2000 && many.snapshot.fraction == 1)
        print("PASS 2000 zero-byte files count correctly")
        let ticks = TransferControl(); ticks.prepare(files: 2, bytes: 100); ticks.beginItem("a", size: 10); ticks.report(1)
        precondition(ticks.snapshot.completedFiles == 0 && ticks.snapshot.fraction < 1)
        ticks.completeFile(); ticks.beginItem("b", size: 90); ticks.report(0.5)
        precondition(ticks.snapshot.completedFiles == 1 && ticks.snapshot.transferredBytes == 55)
        print("PASS byte-weighted progress and completion requires publication")
        print("5 progress scenarios passed")
    }
}
