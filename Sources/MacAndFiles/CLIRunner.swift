import Foundation
import Darwin

extension MTPTransport: DeviceBackend {}

enum CLIRunner {
    static func run(_ arguments: [String]) -> Never {
        // libmtp writes C diagnostics to stdout. Preserve the caller's stdout for
        // the single JSON envelope, then redirect library output to stderr.
        let outputFD = dup(STDOUT_FILENO)
        guard outputFD >= 0, dup2(STDERR_FILENO, STDOUT_FILENO) >= 0 else { exit(1) }
        let output = FileHandle(fileDescriptor: outputFD, closeOnDealloc: true)
        let control = TransferControl()
        signal(SIGINT, SIG_IGN); signal(SIGTERM, SIG_IGN)
        let signals = [SIGINT, SIGTERM].map { number -> DispatchSourceSignal in
            let source = DispatchSource.makeSignalSource(signal: number, queue: .global())
            source.setEventHandler { control.cancel() }; source.resume(); return source
        }
        let executor = CLIExecutor(backend: MTPTransport(), control: control, disconnectOnCancellation: false)
        var code: Int32 = 0
        var envelope: [String: Any] = ["schemaVersion": 1, "app": AppInfo.name, "version": AppInfo.version, "build": AppInfo.build]
        do {
            let request = try CLIRequest(arguments)
            envelope["command"] = request.command
            if request.progress {
                control.onSnapshot = { snapshot in
                    if let data = try? JSONSerialization.data(withJSONObject: snapshot.json.merging(["event": "progress"]) { _, new in new }, options: [.sortedKeys]) {
                        FileHandle.standardError.write(data + Data([10]))
                    }
                }
            }
            envelope["result"] = try executor.run(request); envelope["ok"] = true
        } catch {
            code = CLIExecutor.exitCode(error)
            envelope["ok"] = false
            envelope["error"] = ["code": (error as? BridgeError)?.code ?? "io_error", "message": error.localizedDescription, "exitCode": code]
            envelope["completed"] = executor.completed
            if executor.mutationAttempted { envelope["transfer"] = control.snapshot.json }
            envelope["partialCompletionPossible"] = executor.mutationAttempted
            envelope["androidPartialFilesPossible"] = executor.mutationAttempted && arguments.contains("upload")
        }
        if let data = try? JSONSerialization.data(withJSONObject: envelope, options: [.prettyPrinted, .sortedKeys]) { output.write(data + Data([10])) }
        fflush(stdout); fflush(stderr)
        withExtendedLifetime(signals) { exit(code) }
    }
}
