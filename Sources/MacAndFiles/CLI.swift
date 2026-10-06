import Foundation

protocol DeviceBackend: FileTransport {
    func detect() throws -> [DeviceInfo]
    func connect(id: String) throws -> (String, [StorageInfo])
    func disconnect()
}

struct CLIRequest {
    let command: String
    let options: [String: [String]]
    var progress: Bool { options["progress"] != nil }
    func value(_ key: String) throws -> String {
        guard let value = options[key]?.first else { throw BridgeError("Missing --\(key). See maf help.", code: "invalid_arguments") }
        return value
    }
    init(_ arguments: [String]) throws {
        let args = arguments.first == "--cli" ? Array(arguments.dropFirst()) : arguments
        let command = args.first ?? "help"
        let allowed: [String: Set<String>] = ["help": [], "--help": [], "version": [], "--version": [], "devices": [], "status": [], "storages": ["device"], "ls": ["device", "storage", "path"], "download": ["device", "storage", "path", "to", "progress"], "upload": ["device", "storage", "from", "to", "progress"], "mkdir": ["device", "storage", "path"]]
        guard let keys = allowed[command] else { throw BridgeError("Unknown command: \(command). See maf help.", code: "invalid_arguments") }
        var options: [String: [String]] = [:]
        var i = 1
        while i < args.count {
            let token = args[i]
            guard token.hasPrefix("--"), keys.contains(String(token.dropFirst(2))) else { throw BridgeError("Unexpected argument: \(token)", code: "invalid_arguments") }
            let key = String(token.dropFirst(2))
            guard options[key] == nil || key == "from" else { throw BridgeError("Duplicate option: \(token)", code: "invalid_arguments") }
            if key == "progress" { options[key] = ["true"]; i += 1; continue }
            guard i + 1 < args.count, !args[i + 1].hasPrefix("--"), !args[i + 1].isEmpty else { throw BridgeError("Missing value for \(token)", code: "invalid_arguments") }
            options[key, default: []].append(args[i + 1]); i += 2
        }
        self.command = command; self.options = options
        // Validate all required fields before opening USB, including local paths.
        if !["help", "--help", "version", "--version", "devices", "status"].contains(command) { _ = try value("device") }
        if ["ls", "download", "upload", "mkdir"].contains(command) { _ = try storageID() }
        if ["download", "mkdir"].contains(command) { _ = try RemotePath.components(value("path")) }
        if ["download", "upload"].contains(command) { _ = try value("to") }
        if command == "upload" { _ = try value("from"); _ = try RemotePath.components(value("to")) }
        if command == "ls" { _ = try RemotePath.components(options["path"]?.first ?? "/") }
        if command == "mkdir", try RemotePath.components(value("path")).isEmpty { throw BridgeError("Cannot create the storage root.", code: "invalid_path") }
    }
    func storageID() throws -> UInt32 {
        let raw = try value("storage")
        let parsed = raw.hasPrefix("0x") ? UInt32(raw.dropFirst(2), radix: 16) : UInt32(raw)
        guard let parsed, parsed > 0 else { throw BridgeError("Storage must be a positive UInt32 decimal or 0x hexadecimal ID.", code: "invalid_arguments") }
        return parsed
    }
}

enum RemotePath {
    static func components(_ path: String) throws -> [String] {
        guard path.hasPrefix("/") else { throw BridgeError("Android paths must be absolute, starting with /.", code: "invalid_path") }
        let parts = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        for part in parts { try FileSafety.validateName(part) }
        return parts
    }
    static func resolve(_ path: String, storage: UInt32, backend: FileTransport) throws -> RemoteItem? {
        var parent = UInt32.max
        var result: RemoteItem?
        let parts = try components(path)
        for (index, part) in parts.enumerated() {
            if let result, !result.isFolder { throw BridgeError("Path contains a non-folder: \(result.name)", code: "not_a_directory") }
            let matches = try backend.list(storage: storage, parent: parent).filter { $0.name == part }
            guard matches.count <= 1 else { throw BridgeError("Ambiguous Android path: \(path)", code: "ambiguous_path") }
            guard let item = matches.first else { throw BridgeError("Android path not found: \(parts.prefix(index + 1).joined(separator: "/"))", code: "not_found") }
            result = item; parent = item.id
        }
        return result
    }
    static func folder(_ path: String, storage: UInt32, backend: FileTransport) throws -> UInt32 {
        guard let item = try resolve(path, storage: storage, backend: backend) else { return UInt32.max }
        guard item.isFolder else { throw BridgeError("Not an Android folder: \(path)", code: "not_a_directory") }
        return item.id
    }
}

final class CLIExecutor {
    let backend: DeviceBackend
    let control: TransferControl
    private let disconnectOnCancellation: Bool
    private(set) var completed: [[String: Any]] = []
    private(set) var mutationAttempted = false
    init(backend: DeviceBackend, control: TransferControl = TransferControl(), disconnectOnCancellation: Bool = true) { self.backend = backend; self.control = control; self.disconnectOnCancellation = disconnectOnCancellation }
    func run(_ request: CLIRequest) throws -> [String: Any] {
        if ["help", "--help"].contains(request.command) {
            return ["usage": "maf <command> [options]", "commands": ["devices", "status", "storages --device ID", "ls --device ID --storage ID [--path /]", "upload --device ID --storage ID --from LOCAL [--from LOCAL…] --to /ANDROID_FOLDER [--progress]", "download --device ID --storage ID --path /ANDROID_ITEM --to LOCAL_FOLDER [--progress]", "mkdir --device ID --storage ID --path /NEW_FOLDER", "version"], "output": "One JSON object on stdout. Optional progress JSON lines and library diagnostics on stderr.", "safety": "No overwrite or deletion. Disconnect the GUI before accessing its device. Ctrl-C cancels; completed files remain."]
        }
        if ["version", "--version"].contains(request.command) { return ["name": AppInfo.name, "version": AppInfo.version, "build": AppInfo.build] }
        try control.check()
        if request.command == "devices" { return ["devices": try backend.detect().map { ["id": $0.id, "name": $0.name] }] }
        if request.command == "status" {
            return ["devices": try backend.detect().map { ["id": $0.id, "name": $0.name, "busy": try DeviceAccess.isBusy(id: $0.id)] as [String: Any] }, "lockScope": "MacAndFiles GUI, CLI and diagnostics; third-party USB ownership is not detected"]
        }
        // Validate local destinations/sources before connecting.
        var local: URL?
        var sources: [URL] = []
        if request.command == "download" {
            local = URL(fileURLWithPath: try request.value("to")).standardizedFileURL
            let info = try local!.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard info.isDirectory == true, info.isSymbolicLink != true else { throw BridgeError("--to must be an existing Mac directory, not a symlink.", code: "invalid_path") }
        }
        if request.command == "upload" {
            sources = request.options["from"]!.map { URL(fileURLWithPath: $0).standardizedFileURL }
            for source in sources { _ = try FileSafety.localKind(source); try FileSafety.validateName(source.lastPathComponent) }
        }
        let deviceID = try request.value("device")
        let (name, storages) = try backend.connect(id: deviceID)
        // CLI cancellation exits immediately after reporting. Avoid another blocking
        // MTP CloseSession on a device that may no longer answer; process exit
        // closes USB descriptors and releases the advisory lock. GUI/test callers
        // retain normal explicit cleanup.
        defer { if !control.cancelled || disconnectOnCancellation { backend.disconnect() } }
        try control.check()
        if request.command == "storages" { return ["device": ["id": deviceID, "name": name], "storages": storages.map { ["id": $0.id, "name": $0.name, "capacityBytes": $0.capacity, "freeBytes": $0.free] as [String: Any] }] }
        let storage = try request.storageID()
        guard storages.contains(where: { $0.id == storage }) else { throw BridgeError("Storage ID does not belong to this device.", code: "storage_not_found") }
        switch request.command {
        case "ls":
            let path = request.options["path"]?.first ?? "/"
            let folder = try RemotePath.folder(path, storage: storage, backend: backend)
            let items = try backend.list(storage: storage, parent: folder)
            try control.check()
            return ["deviceID": deviceID, "storageID": storage, "path": path, "items": items.map { ["id": $0.id, "name": $0.name, "sizeBytes": $0.size, "kind": $0.isFolder ? "folder" : "file", "modifiedUnixSeconds": $0.modified.timeIntervalSince1970] as [String: Any] }]
        case "mkdir":
            var parts = try RemotePath.components(request.value("path")); let child = parts.removeLast()
            let parent = try RemotePath.folder("/" + parts.joined(separator: "/"), storage: storage, backend: backend)
            guard !(try backend.list(storage: storage, parent: parent)).contains(where: { $0.name == child }) else { throw BridgeError("An item already exists at this path.", code: "already_exists") }
            try control.check(); mutationAttempted = true
            let id = try backend.mkdir(child, storage: storage, parent: parent)
            return ["id": id, "path": try request.value("path"), "deviceID": deviceID, "storageID": storage]
        case "download", "upload":
            var engine = TransferEngine(transport: backend, control: control, status: { _ in })
            engine.completed = { receipt in
                self.completed.append(["direction": receipt.direction, "localPath": receipt.localPath, "storageID": receipt.storage, receipt.direction == "upload" && receipt.kind == "file" ? "parentID" : "objectID": receipt.object, "kind": receipt.kind])
            }
            if request.command == "download" {
                guard let item = try RemotePath.resolve(request.value("path"), storage: storage, backend: backend) else { throw BridgeError("Select an item beneath the storage root.", code: "invalid_path") }
                try control.check(); mutationAttempted = true
                try engine.download([item], storage: storage, to: local!)
            } else {
                let parent = try RemotePath.folder(request.value("to"), storage: storage, backend: backend)
                try control.check(); mutationAttempted = true
                try engine.upload(sources, storage: storage, parent: parent)
            }
            return ["deviceID": deviceID, "storageID": storage, "completed": completed, "transfer": control.snapshot.json]
        default: throw BridgeError("Unknown command.", code: "invalid_arguments")
        }
    }
    static func exitCode(_ error: Error) -> Int32 {
        switch (error as? BridgeError)?.code {
        case "invalid_arguments", "invalid_path": return 2
        case "device_not_found", "storage_not_found", "not_found": return 3
        case "device_busy": return 4
        case "already_exists", "ambiguous_path", "unsupported_file", "not_a_directory": return 5
        case "cancelled": return 130
        default: return 1
        }
    }
}
