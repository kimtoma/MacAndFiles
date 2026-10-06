import Foundation

struct BridgeError: LocalizedError {
    let message: String
    let code: String
    init(_ message: String, code: String = "transfer_failed") { self.message = message; self.code = code }
    var errorDescription: String? { message }
}

struct DeviceInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}

struct StorageInfo: Identifiable, Hashable, Sendable {
    let id: UInt32
    let name: String
    let capacity: UInt64
    let free: UInt64
}

struct RemoteItem: Identifiable, Hashable, Sendable {
    let id: UInt32
    let name: String
    let size: UInt64
    let isFolder: Bool
    let modified: Date
    var symbol: String {
        if isFolder { return "folder.fill" }
        switch (name as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "webp", "heic": return "photo"
        case "mp4", "mov", "mkv": return "film"
        case "mp3", "m4a", "wav", "flac": return "music.note"
        default: return "doc"
        }
    }
}

enum FileSafety {
    static func validateName(_ name: String) throws {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"),
              !name.contains("\0"), !name.contains(":"), name.utf8.count <= 255 else {
            throw BridgeError(L10n.text("Invalid file name: %@", name), code: "invalid_path")
        }
    }
    static func destination(_ directory: URL, name: String) throws -> URL {
        try validateName(name)
        let result = directory.appendingPathComponent(name)
        // Check resource values as well: dangling symlinks must count as existing.
        if FileManager.default.fileExists(atPath: result.path) ||
            (try? result.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true {
            throw BridgeError(L10n.text("“%@” already exists. Nothing was overwritten.", name), code: "already_exists")
        }
        return result
    }
    static func localKind(_ url: URL) throws -> Bool {
        let v = try url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey, .isRegularFileKey])
        guard v.isSymbolicLink != true else { throw BridgeError(L10n.text("Symbolic links are not transferred: %@", url.lastPathComponent), code: "unsupported_file") }
        guard v.isDirectory == true || v.isRegularFile == true else {
            throw BridgeError(L10n.text("Only regular files and folders can be transferred."), code: "unsupported_file")
        }
        return v.isDirectory == true
    }
}

/// All calls are serialized by Session. Test implementations need no USB device.
protocol FileTransport {
    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem]
    func receive(_ item: RemoteItem, to: URL, control: TransferControl) throws
    func send(_ url: URL, storage: UInt32, parent: UInt32, control: TransferControl) throws
    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32
}

struct TransferReceipt {
    let direction: String
    let localPath: String
    let storage: UInt32
    let object: UInt32
    let kind: String
}

struct TransferEngine {
    let transport: FileTransport
    let control: TransferControl
    let status: @Sendable (String) -> Void
    var completed: (TransferReceipt) -> Void = { _ in }

    private struct DownloadNode { let item: RemoteItem; let children: [DownloadNode] }
    private struct UploadNode { let url: URL; let directory: Bool; let size: UInt64; let children: [UploadNode] }
    private struct Inventory {
        var files = 0
        var bytes: UInt64 = 0
        mutating func add(_ size: UInt64) throws {
            let sum = bytes.addingReportingOverflow(size)
            guard !sum.overflow, files < 1_000_000 else { throw BridgeError(L10n.text("The transfer is too large to plan safely.")) }
            files += 1; bytes = sum.partialValue
        }
    }
    private func downloadPlan(_ items: [RemoteItem], storage: UInt32, depth: Int, inventory: inout Inventory) throws -> [DownloadNode] {
        guard depth < 128 else { throw BridgeError(L10n.text("The folder depth limit was exceeded.")) }
        return try items.map { item in
            try control.check(); control.setContext(item.name); try FileSafety.validateName(item.name)
            if item.isFolder {
                let children = try downloadPlan(transport.list(storage: storage, parent: item.id), storage: storage, depth: depth + 1, inventory: &inventory)
                return DownloadNode(item: item, children: children)
            }
            try inventory.add(item.size)
            return DownloadNode(item: item, children: [])
        }
    }
    private func uploadPlan(_ urls: [URL], depth: Int, inventory: inout Inventory) throws -> [UploadNode] {
        guard depth < 128 else { throw BridgeError(L10n.text("The folder depth limit was exceeded.")) }
        return try urls.map { url in
            try control.check(); control.setContext(url.path); try FileSafety.validateName(url.lastPathComponent)
            let directory = try FileSafety.localKind(url)
            if directory {
                let children = try uploadPlan(FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isSymbolicLinkKey]).sorted { $0.path < $1.path }, depth: depth + 1, inventory: &inventory)
                return UploadNode(url: url, directory: true, size: 0, children: children)
            }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            guard let size, size >= 0 else { throw BridgeError(L10n.text("Couldn’t read file size.")) }
            try inventory.add(UInt64(size))
            return UploadNode(url: url, directory: false, size: UInt64(size), children: [])
        }
    }
    func download(_ items: [RemoteItem], storage: UInt32, to directory: URL, depth: Int = 0) throws {
        do {
            status(L10n.text("Preparing Transfer…"))
            var inventory = Inventory()
            let plan = try downloadPlan(items, storage: storage, depth: depth, inventory: &inventory)
            control.prepare(files: inventory.files, bytes: inventory.bytes)
            try download(plan, storage: storage, to: directory)
            control.finish()
        } catch { control.recordFailure(error); throw error }
    }
    private func download(_ nodes: [DownloadNode], storage: UInt32, to directory: URL) throws {
        let targets = try nodes.map { node in
            control.setContext(directory.appendingPathComponent(node.item.name).path)
            return try FileSafety.destination(directory, name: node.item.name)
        }
        guard Set(targets.map(\.path)).count == targets.count else { throw BridgeError(L10n.text("Duplicate file names were found."), code: "ambiguous_path") }
        for (node, target) in zip(nodes, targets) {
            try control.check()
            let item = node.item
            control.beginItem(target.path, size: item.isFolder ? 0 : item.size)
            status(L10n.text("Copying to Mac · %@", item.name))
            if item.isFolder {
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
                completed(TransferReceipt(direction: "download", localPath: target.path, storage: storage, object: item.id, kind: "folder_created"))
                try download(node.children, storage: storage, to: target)
            } else {
                let temporary = directory.appendingPathComponent(".androidbridge-\(UUID().uuidString).partial")
                defer { try? FileManager.default.removeItem(at: temporary) }
                try transport.receive(item, to: temporary, control: control)
                try control.check()
                let size = try temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? -1
                guard size >= 0, UInt64(size) == item.size else { throw BridgeError(L10n.text("Downloaded file size does not match: %@", item.name)) }
                try FileManager.default.moveItem(at: temporary, to: target)
                control.completeFile()
                completed(TransferReceipt(direction: "download", localPath: target.path, storage: storage, object: item.id, kind: "file"))
            }
        }
    }
    func upload(_ urls: [URL], storage: UInt32, parent: UInt32, depth: Int = 0) throws {
        do {
            status(L10n.text("Preparing Transfer…"))
            var inventory = Inventory()
            let plan = try uploadPlan(urls, depth: depth, inventory: &inventory)
            control.prepare(files: inventory.files, bytes: inventory.bytes)
            try upload(plan, storage: storage, parent: parent)
            control.finish()
        } catch { control.recordFailure(error); throw error }
    }
    private func upload(_ nodes: [UploadNode], storage: UInt32, parent: UInt32) throws {
        let existing = Set(try transport.list(storage: storage, parent: parent).map(\.name))
        let names = nodes.map { $0.url.lastPathComponent }
        guard Set(names).count == names.count else { throw BridgeError(L10n.text("The selected items contain duplicate file names."), code: "ambiguous_path") }
        for node in nodes {
            control.setContext(node.url.path)
            guard !existing.contains(node.url.lastPathComponent) else { throw BridgeError(L10n.text("“%@” already exists on Android. Nothing was overwritten.", node.url.lastPathComponent), code: "already_exists") }
        }
        for node in nodes {
            try control.check()
            let url = node.url
            control.setContext(url.path)
            // Reject changed sources, including replacement with a symlink after planning.
            guard try FileSafety.localKind(url) == node.directory else { throw BridgeError(L10n.text("The source changed while preparing the transfer.")) }
            if !node.directory {
                guard try url.resourceValues(forKeys: [.fileSizeKey]).fileSize == Int(exactly: node.size) else { throw BridgeError(L10n.text("The source changed while preparing the transfer.")) }
            }
            control.beginItem(url.path, size: node.size)
            status(L10n.text("Copying to Android · %@", url.lastPathComponent))
            if node.directory {
                let folder = try transport.mkdir(url.lastPathComponent, storage: storage, parent: parent)
                completed(TransferReceipt(direction: "upload", localPath: url.path, storage: storage, object: folder, kind: "folder_created"))
                try upload(node.children, storage: storage, parent: folder)
            } else {
                try transport.send(url, storage: storage, parent: parent, control: control)
                try control.check()
                control.completeFile()
                completed(TransferReceipt(direction: "upload", localPath: url.path, storage: storage, object: parent, kind: "file"))
            }
        }
    }
}
