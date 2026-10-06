import Foundation

struct TransferFailure: Sendable {
    let item: String
    let message: String
    let code: String
    var json: [String: Any] { ["item": item, "message": message, "code": code] }
}

struct TransferSnapshot: Sendable {
    var totalFiles = 0
    var completedFiles = 0
    var totalBytes: UInt64 = 0
    var transferredBytes: UInt64 = 0
    var activeItem = ""
    var activeFileFraction = 0.0
    var bytesPerSecond = 0.0
    var elapsedSeconds = 0.0
    var finished = false
    var failures: [TransferFailure] = []
    var fraction: Double {
        if finished { return 1 }
        if totalBytes > 0 { return min(0.999, Double(transferredBytes) / Double(totalBytes)) }
        return totalFiles > 0 ? min(0.999, Double(completedFiles) / Double(totalFiles)) : 0
    }
    var remainingSeconds: Double? {
        guard elapsedSeconds >= 1, bytesPerSecond > 0, transferredBytes < totalBytes else { return nil }
        return Double(totalBytes - transferredBytes) / bytesPerSecond
    }
    var json: [String: Any] {
        var result: [String: Any] = ["totalFiles": totalFiles, "completedFiles": completedFiles,
            "totalBytes": totalBytes, "transferredBytes": transferredBytes, "overallFraction": fraction,
            "activeItem": activeItem, "activeFileFraction": activeFileFraction,
            "bytesPerSecond": bytesPerSecond, "elapsedSeconds": elapsedSeconds,
            "finished": finished, "failedItems": failures.map(\.json)]
        if let remainingSeconds { result["remainingSeconds"] = remainingSeconds }
        return result
    }
}

/// Callbacks run outside the lock. Completion counts change only after a verified
/// file is published, never merely because libmtp reported 100 percent.
final class TransferControl: @unchecked Sendable {
    private let lock = NSLock()
    private var stopped = false
    private var lastReport = -Double.infinity
    private var started = ProcessInfo.processInfo.systemUptime
    private var state = TransferSnapshot()
    private var completedBytes: UInt64 = 0
    private var activeBytes: UInt64 = 0
    private var activeSize: UInt64 = 0
    var onProgress: @Sendable (Double) -> Void = { _ in }
    var onSnapshot: @Sendable (TransferSnapshot) -> Void = { _ in }
    func cancel() { lock.lock(); stopped = true; lock.unlock() }
    var cancelled: Bool { lock.lock(); defer { lock.unlock() }; return stopped }
    var snapshot: TransferSnapshot { lock.lock(); defer { lock.unlock() }; return state }
    func check() throws { if cancelled { throw BridgeError(L10n.text("Transfer canceled. Completed files are preserved."), code: "cancelled") } }
    func prepare(files: Int, bytes: UInt64) {
        lock.lock()
        state = TransferSnapshot(); state.totalFiles = files; state.totalBytes = bytes
        completedBytes = 0; activeBytes = 0; activeSize = 0
        started = ProcessInfo.processInfo.systemUptime
        lock.unlock(); emit(force: true)
    }
    func setContext(_ item: String) { lock.lock(); state.activeItem = item; lock.unlock() }
    func beginItem(_ name: String, size: UInt64 = 0) {
        lock.lock(); state.activeItem = name; state.activeFileFraction = 0
        activeSize = size; activeBytes = 0; lock.unlock(); emit(force: true)
    }
    func report(_ fraction: Double) {
        lock.lock()
        let value = fraction.isFinite ? min(1, max(0, fraction)) : 0
        state.activeFileFraction = max(state.activeFileFraction, value)
        activeBytes = value >= 1 ? activeSize : min(activeSize, UInt64(Double(activeSize) * value))
        lock.unlock(); emit(force: value >= 1)
    }
    func completeFile() {
        lock.lock(); state.completedFiles += 1
        completedBytes += activeSize; activeBytes = 0; activeSize = 0
        state.activeFileFraction = 1; lock.unlock(); emit(force: true)
    }
    func finish() {
        lock.lock(); state.finished = true; state.activeItem = ""; lock.unlock(); emit(force: true)
    }
    func recordFailure(_ error: Error) {
        lock.lock()
        state.failures.append(TransferFailure(item: state.activeItem, message: error.localizedDescription,
            code: (error as? BridgeError)?.code ?? "io_error"))
        lock.unlock(); emit(force: true)
    }
    private func emit(force: Bool) {
        lock.lock()
        let now = ProcessInfo.processInfo.systemUptime
        state.transferredBytes = completedBytes + activeBytes
        state.elapsedSeconds = max(0, now - started)
        state.bytesPerSecond = state.elapsedSeconds > 0 ? Double(state.transferredBytes) / state.elapsedSeconds : 0
        let shouldReport = force || now - lastReport >= 0.1
        if shouldReport { lastReport = now }
        let value = state
        lock.unlock()
        if shouldReport { onProgress(value.activeFileFraction); onSnapshot(value) }
    }
}
