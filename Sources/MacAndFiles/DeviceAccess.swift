import Foundation
import Darwin

/// Held for the entire MTP session. Kernel releases the lock even after a crash.
final class DeviceAccess {
    private let descriptor: Int32
    init(id: String, directory: URL? = nil) throws {
        let base = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("local.androidbridge.mac/usb-locks")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let name = id.utf8.map { String(format: "%02x", $0) }.joined()
        let fd = open(base.appendingPathComponent(name + ".lock").path, O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw BridgeError("Cannot open the USB session lock.", code: "lock_failed") }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_uid == geteuid(), (info.st_mode & S_IFMT) == S_IFREG else {
            close(fd); throw BridgeError("Invalid USB session lock file.", code: "lock_failed")
        }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            let busy = errno == EWOULDBLOCK
            close(fd)
            throw BridgeError(L10n.text("Couldn’t open the USB connection. Unlock the device, allow file transfer, and quit other USB apps such as Android File Transfer."), code: busy ? "device_busy" : "lock_failed")
        }
        descriptor = fd
    }
    static func isBusy(id: String) throws -> Bool {
        do { let lock = try DeviceAccess(id: id); withExtendedLifetime(lock) {}; return false }
        catch let error as BridgeError where error.code == "device_busy" { return true }
    }
    deinit { flock(descriptor, LOCK_UN); close(descriptor) }
}
