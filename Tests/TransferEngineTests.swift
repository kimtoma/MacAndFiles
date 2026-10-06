import Foundation

// Standalone test runner: Command Line Tools do not ship XCTest.
func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #file, line: UInt = #line) {
    precondition(actual == expected, "Expected \(expected), got \(actual)", file: file, line: line)
}
func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
    do { _ = try expression(); preconditionFailure("Expected error", file: file, line: line) } catch { }
}

final class FakeTransport: FileTransport {
    var folders: [UInt32: [RemoteItem]] = [:]
    var payloads: [UInt32: Data] = [:]
    var sent: [String] = []
    var created: [String] = []
    var failReceive = false
    var nextID: UInt32 = 100
    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem] { folders[parent] ?? [] }
    func receive(_ item: RemoteItem, to: URL, control: TransferControl) throws {
        try (payloads[item.id] ?? Data()).write(to: to)
        if failReceive { throw BridgeError("USB disconnected") }
    }
    func send(_ url: URL, storage: UInt32, parent: UInt32, control: TransferControl) throws { sent.append(url.lastPathComponent) }
    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32 { created.append(name); nextID += 1; return nextID }
}

final class TransferEngineTests {
    var root: URL!
    func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    }
    func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }
    func item(_ name: String, id: UInt32 = 1, size: UInt64 = 3, folder: Bool = false) -> RemoteItem {
        RemoteItem(id: id, name: name, size: size, isFolder: folder, modified: Date())
    }
    func engine(_ transport: FakeTransport, _ control: TransferControl = TransferControl()) -> TransferEngine {
        TransferEngine(transport: transport, control: control, status: { _ in })
    }
    func testUnicodeDownloadAndExactBytes() throws {
        let transport = FakeTransport(); transport.payloads[1] = Data([0, 7, 255])
        try engine(transport).download([item("한글 문서.bin")], storage: 1, to: root)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("한글 문서.bin")), Data([0, 7, 255]))
    }
    func testTraversalIsRejectedBeforeWrite() throws {
        for name in ["../secret", "..", ".", "/etc/file", "", "bad\0name", "bad:name"] {
            XCTAssertThrowsError(try engine(FakeTransport()).download([item(name)], storage: 1, to: root))
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }
    func testExistingDownloadNeverOverwrites() throws {
        let target = root.appendingPathComponent("file.txt")
        try Data("original".utf8).write(to: target)
        XCTAssertThrowsError(try engine(FakeTransport()).download([item("file.txt")], storage: 1, to: root))
        XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "original")
    }
    func testFailureRemovesPartialDownload() throws {
        let transport = FakeTransport(); transport.payloads[1] = Data([1, 2, 3]); transport.failReceive = true
        XCTAssertThrowsError(try engine(transport).download([item("file.bin")], storage: 1, to: root))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }
    func testWrongSizeNeverPublishesFinalFile() throws {
        let transport = FakeTransport(); transport.payloads[1] = Data([1])
        XCTAssertThrowsError(try engine(transport).download([item("file.bin")], storage: 1, to: root))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }
    func testRecursiveDownload() throws {
        let transport = FakeTransport(); transport.folders[10] = [item("child.bin")]; transport.payloads[1] = Data([1, 2, 3])
        try engine(transport).download([item("folder", id: 10, folder: true)], storage: 1, to: root)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("folder/child.bin")), Data([1, 2, 3]))
    }
    func testCancelledBatchWritesNothing() throws {
        let token = TransferControl(); token.cancel()
        XCTAssertThrowsError(try engine(FakeTransport(), token).download([item("file")], storage: 1, to: root))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }
    func testUploadCollisionPreflightsEntireBatch() throws {
        let a = root.appendingPathComponent("a"), b = root.appendingPathComponent("b")
        try Data().write(to: a); try Data().write(to: b)
        let transport = FakeTransport(); transport.folders[UInt32.max] = [item("b")]
        XCTAssertThrowsError(try engine(transport).upload([a, b], storage: 1, parent: UInt32.max))
        XCTAssertEqual(transport.sent, [])
    }
    func testSymlinksAreNotFollowed() throws {
        let target = root.appendingPathComponent("real"), link = root.appendingPathComponent("link")
        try Data().write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        let transport = FakeTransport()
        XCTAssertThrowsError(try engine(transport).upload([link], storage: 1, parent: UInt32.max))
        XCTAssertEqual(transport.sent, [])
    }
    func testRecursiveUpload() throws {
        let folder = root.appendingPathComponent("한글 폴더")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        try Data([1]).write(to: folder.appendingPathComponent("child.bin"))
        let transport = FakeTransport()
        try engine(transport).upload([folder], storage: 1, parent: UInt32.max)
        XCTAssertEqual(transport.created, ["한글 폴더"]); XCTAssertEqual(transport.sent, ["child.bin"])
    }
    func testDuplicateRemoteNamesRejectedBeforeDownload() throws {
        XCTAssertThrowsError(try engine(FakeTransport()).download([item("same", id: 1), item("same", id: 2)], storage: 1, to: root))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }
}

@main
enum TestRunner {
    static func main() throws {
        let suite = TransferEngineTests()
        let cases: [(String, () throws -> Void)] = [
            ("UnicodeDownloadAndExactBytes", suite.testUnicodeDownloadAndExactBytes),
            ("TraversalRejected", suite.testTraversalIsRejectedBeforeWrite),
            ("NoOverwrite", suite.testExistingDownloadNeverOverwrites),
            ("PartialCleanup", suite.testFailureRemovesPartialDownload),
            ("SizeMismatch", suite.testWrongSizeNeverPublishesFinalFile),
            ("RecursiveDownload", suite.testRecursiveDownload),
            ("Cancellation", suite.testCancelledBatchWritesNothing),
            ("BatchCollision", suite.testUploadCollisionPreflightsEntireBatch),
            ("SymlinkRejected", suite.testSymlinksAreNotFollowed),
            ("RecursiveUpload", suite.testRecursiveUpload),
            ("DuplicateRemoteNames", suite.testDuplicateRemoteNamesRejectedBeforeDownload)
        ]
        for (name, test) in cases {
            try suite.setUpWithError()
            do { try test(); try suite.tearDownWithError(); print("PASS \(name)") }
            catch { try? suite.tearDownWithError(); throw error }
        }
        print("\(cases.count) tests passed")
    }
}
