import Foundation
import CLibMTP

private let progressCallback: LIBMTP_progressfunc_t = { sent, total, opaque in
    guard let opaque else { return 0 }
    let control = Unmanaged<TransferControl>.fromOpaque(opaque).takeUnretainedValue()
    control.report(total == 0 ? 0 : Double(sent) / Double(total))
    return control.cancelled ? 1 : 0
}

final class MTPTransport: FileTransport {
    private var access: DeviceAccess?
    private var device: UnsafeMutablePointer<LIBMTP_mtpdevice_t>?
    init() { LIBMTP_Init() }
    deinit { disconnect() }

    func detect() throws -> [DeviceInfo] {
        var raw: UnsafeMutablePointer<LIBMTP_raw_device_t>?
        var count: Int32 = 0
        let result = LIBMTP_Detect_Raw_Devices(&raw, &count)
        defer { free(raw) }
        if result == LIBMTP_ERROR_NO_DEVICE_ATTACHED { return [] }
        guard result == LIBMTP_ERROR_NONE else { throw BridgeError(L10n.text("USB device detection failed (%ld). Check the cable and USB file transfer mode.", Int(result.rawValue))) }
        guard let raw else { return [] }
        return (0..<Int(count)).map {
            let d = raw[$0]
            return DeviceInfo(id: key(d), name: [string(d.device_entry.vendor), string(d.device_entry.product)].filter { !$0.isEmpty }.joined(separator: " "))
        }
    }

    private func key(_ raw: LIBMTP_raw_device_t) -> String {
        "\(raw.bus_location):\(raw.devnum):\(raw.device_entry.vendor_id):\(raw.device_entry.product_id)"
    }
    private func string(_ p: UnsafePointer<CChar>?) -> String { p.map { String(cString: $0) } ?? "" }
    func disconnect() { if let device { LIBMTP_Release_Device(device) }; device = nil; access = nil }
    private func connected() throws -> UnsafeMutablePointer<LIBMTP_mtpdevice_t> {
        guard let device else { throw BridgeError(L10n.text("Connect an Android device first.")) }
        return device
    }
    private func error(_ context: String) -> BridgeError {
        guard let device else { return BridgeError(context) }
        var cursor = LIBMTP_Get_Errorstack(device)
        var parts: [String] = []
        while let e = cursor { parts.append(string(e.pointee.error_text)); cursor = e.pointee.next }
        LIBMTP_Clear_Errorstack(device)
        return BridgeError(([context] + parts).joined(separator: "\n"))
    }

    func connect(id: String) throws -> (String, [StorageInfo]) {
        disconnect()
        var raw: UnsafeMutablePointer<LIBMTP_raw_device_t>?
        var count: Int32 = 0
        let result = LIBMTP_Detect_Raw_Devices(&raw, &count)
        defer { free(raw) }
        guard result == LIBMTP_ERROR_NONE, let raw,
              let index = (0..<Int(count)).first(where: { key(raw[$0]) == id }) else {
            throw BridgeError(L10n.text("The device was disconnected or its USB mode changed. Scan again."), code: "device_not_found")
        }
        access = try DeviceAccess(id: id)
        device = LIBMTP_Open_Raw_Device_Uncached(raw.advanced(by: index))
        guard let device else { access = nil; throw BridgeError(L10n.text("Couldn’t open the USB connection. Unlock the device, allow file transfer, and quit other USB apps such as Android File Transfer."), code: "usb_open_failed") }
        do {
            let model = LIBMTP_Get_Modelname(device)
            let name = string(model)
            free(model)
            let storage = try storages()
            guard !storage.isEmpty else { throw BridgeError(L10n.text("No storage is available. Unlock the device and allow USB file transfer.")) }
            return (name.isEmpty ? "Android" : name, storage)
        } catch { disconnect(); throw error }
    }

    func storages() throws -> [StorageInfo] {
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        guard LIBMTP_Get_Storage(d, 0) >= 0 else { throw error(L10n.text("Couldn’t read storage information.")) }
        var cursor = d.pointee.storage
        var items: [StorageInfo] = []
        while let s = cursor {
            let value = s.pointee
            items.append(StorageInfo(id: value.id, name: string(value.StorageDescription).isEmpty ? L10n.text("Internal Storage") : string(value.StorageDescription), capacity: value.MaxCapacity, free: value.FreeSpaceInBytes))
            cursor = value.next
        }
        return items
    }

    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem] {
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        var cursor = LIBMTP_Get_Files_And_Folders(d, storage, parent)
        var items: [RemoteItem] = []
        while let p = cursor {
            let value = p.pointee
            cursor = value.next
            items.append(RemoteItem(id: value.item_id, name: string(value.filename), size: value.filesize,
                                    isFolder: value.filetype == LIBMTP_FILETYPE_FOLDER,
                                    modified: Date(timeIntervalSince1970: Double(value.modificationdate))))
            LIBMTP_destroy_file_t(p)
        }
        if LIBMTP_Get_Errorstack(d) != nil { throw error(L10n.text("Couldn’t read the folder listing. Check the USB connection.")) }
        return items.sorted {
            $0.isFolder != $1.isFolder ? $0.isFolder : $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func receive(_ item: RemoteItem, to url: URL, control: TransferControl) throws {
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        let opaque = UnsafeRawPointer(Unmanaged.passUnretained(control).toOpaque())
        let result = url.path.withCString { LIBMTP_Get_File_To_File(d, item.id, $0, progressCallback, opaque) }
        if result != 0 {
            if control.cancelled { LIBMTP_Clear_Errorstack(d); try control.check() }
            throw error(L10n.text("Couldn’t copy to Mac: %@", item.name))
        }
    }

    func send(_ url: URL, storage: UInt32, parent: UInt32, control: TransferControl) throws {
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        guard let meta = LIBMTP_new_file_t() else { throw BridgeError(L10n.text("Not enough memory.")) }
        defer { LIBMTP_destroy_file_t(meta) }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        meta.pointee.filename = strdup(url.lastPathComponent)
        meta.pointee.filesize = UInt64(size)
        meta.pointee.storage_id = storage
        // Preserve the explicit MTP root sentinel, including SendObjectInfo devices.
        meta.pointee.parent_id = parent
        meta.pointee.filetype = LIBMTP_FILETYPE_UNKNOWN
        let opaque = UnsafeRawPointer(Unmanaged.passUnretained(control).toOpaque())
        let result = url.path.withCString { LIBMTP_Send_File_From_File(d, $0, meta, progressCallback, opaque) }
        guard result == 0 else {
            if control.cancelled {
                LIBMTP_Clear_Errorstack(d)
                throw BridgeError(L10n.text("Transfer canceled. Check Android for partial files."), code: "cancelled")
            }
            throw error(L10n.text("Couldn’t copy to Android: %@. A partial file may remain.", url.lastPathComponent))
        }
        guard let received = LIBMTP_Get_Filemetadata(d, meta.pointee.item_id) else { throw error(L10n.text("Couldn’t verify the file after transfer.")) }
        defer { LIBMTP_destroy_file_t(received) }
        guard received.pointee.filesize == UInt64(size) else { throw BridgeError(L10n.text("The file size reported by Android does not match.")) }
    }

    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32 {
        try FileSafety.validateName(name)
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        let cName = strdup(name)
        defer { free(cName) }
        let id = LIBMTP_Create_Folder(d, cName, parent, storage)
        guard id != 0 else { throw error(L10n.text("Couldn’t create the folder: %@", name)) }
        return id
    }

    func removeVerificationFolder(_ folder: RemoteItem, storage: UInt32) throws {
        guard folder.isFolder, folder.name.hasPrefix("AndroidBridge-Test-"),
              UUID(uuidString: String(folder.name.dropFirst("AndroidBridge-Test-".count))) != nil else {
            throw BridgeError(L10n.text("Only verification folders can be cleaned up."))
        }
        let children = try list(storage: storage, parent: folder.id)
        guard Set(children.map(\.name)) == Set(["한글 문서.txt", "empty.bin", "한글 폴더"]),
              let nested = children.first(where: { $0.name == "한글 폴더" && $0.isFolder }) else {
            throw BridgeError(L10n.text("The test folder has unexpected contents. Automatic cleanup stopped."))
        }
        let nestedItems = try list(storage: storage, parent: nested.id)
        guard nestedItems.count == 1, nestedItems[0].name == "binary-5MiB.bin", !nestedItems[0].isFolder else {
            throw BridgeError(L10n.text("The test subfolder has unexpected contents."))
        }
        let d = try connected()
        for item in nestedItems + children.filter({ !$0.isFolder }) + [nested, folder] {
            LIBMTP_Clear_Errorstack(d)
            guard LIBMTP_Delete_Object(d, item.id) == 0 else { throw error(L10n.text("Couldn’t clean up the test file: %@", item.name)) }
        }
    }

    /// Stress-test cleanup is separate from ordinary file operations. Only a
    /// UUID fixture root and enumerated test names are eligible; preflight the
    /// complete tree before deleting anything.
    func removeStressVerificationFolder(_ folder: RemoteItem, storage: UInt32) throws {
        let prefix = "AndroidBridge-Test-"
        guard folder.isFolder, folder.name.hasPrefix(prefix), UUID(uuidString: String(folder.name.dropFirst(prefix.count))) != nil else {
            throw BridgeError(L10n.text("Only verification folders can be cleaned up."))
        }
        var cleanup: [RemoteItem] = []
        let fixedFiles: Set<String> = ["한글 문서.txt", "empty.bin", "binary-5MiB.bin", "large-4GiB-plus.bin", "cancel.bin"]
        func visit(_ parent: RemoteItem, depth: Int) throws {
            guard depth < 4, cleanup.count < 10_000 else { throw BridgeError(L10n.text("The test folder has unexpected contents. Automatic cleanup stopped.")) }
            for item in try list(storage: storage, parent: parent.id) {
                if item.isFolder {
                    guard ["한글 폴더", "small-files"].contains(item.name) else { throw BridgeError(L10n.text("The test folder has unexpected contents. Automatic cleanup stopped.")) }
                    try visit(item, depth: depth + 1)
                } else {
                    let tiny = item.name.range(of: "^tiny-[0-9]{4}\\.bin$", options: .regularExpression) != nil
                    guard fixedFiles.contains(item.name) || tiny else { throw BridgeError(L10n.text("The test folder has unexpected contents. Automatic cleanup stopped.")) }
                    cleanup.append(item)
                }
            }
            cleanup.append(parent)
        }
        try visit(folder, depth: 0)
        let device = try connected()
        for item in cleanup {
            LIBMTP_Clear_Errorstack(device)
            guard LIBMTP_Delete_Object(device, item.id) == 0 else { throw error(L10n.text("Couldn’t clean up the test file: %@", item.name)) }
        }
    }

    func removeVerificationFile(_ file: RemoteItem) throws {
        let prefix = "AndroidBridge-Test-file-"
        guard !file.isFolder, file.name.hasPrefix(prefix), file.name.hasSuffix(".txt"),
              UUID(uuidString: String(file.name.dropFirst(prefix.count).dropLast(4))) != nil else {
            throw BridgeError(L10n.text("Only verification files can be cleaned up."))
        }
        let d = try connected()
        LIBMTP_Clear_Errorstack(d)
        guard LIBMTP_Delete_Object(d, file.id) == 0 else { throw error(L10n.text("Couldn’t clean up the test file.")) }
    }
}

/// Owns all libmtp pointers and confines every USB operation to one actor.
actor Session {
    private let mtp = MTPTransport()
    func detect() throws -> [DeviceInfo] { try mtp.detect() }
    func connect(_ id: String) throws -> (String, [StorageInfo]) { try mtp.connect(id: id) }
    func disconnect() { mtp.disconnect() }
    func list(storage: UInt32, parent: UInt32) throws -> [RemoteItem] { try mtp.list(storage: storage, parent: parent) }
    func storages() throws -> [StorageInfo] { try mtp.storages() }
    func download(_ items: [RemoteItem], storage: UInt32, to: URL, control: TransferControl, status: @escaping @Sendable (String) -> Void) throws {
        try TransferEngine(transport: mtp, control: control, status: status).download(items, storage: storage, to: to)
    }
    func upload(_ urls: [URL], storage: UInt32, parent: UInt32, control: TransferControl, status: @escaping @Sendable (String) -> Void) throws {
        try TransferEngine(transport: mtp, control: control, status: status).upload(urls, storage: storage, parent: parent)
    }
    func mkdir(_ name: String, storage: UInt32, parent: UInt32) throws {
        guard !(try mtp.list(storage: storage, parent: parent)).contains(where: { $0.name == name }) else { throw BridgeError(L10n.text("An item with the same name already exists.")) }
        _ = try mtp.mkdir(name, storage: storage, parent: parent)
    }
}
