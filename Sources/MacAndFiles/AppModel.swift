import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var devices: [DeviceInfo] = []
    @Published var selectedDevice = ""
    @Published var deviceName = ""
    @Published var storages: [StorageInfo] = []
    @Published var storageID: UInt32 = 0
    @Published var items: [RemoteItem] = []
    @Published var selection: Set<UInt32> = []
    @Published var search = ""
    @Published var searchPresented = false
    @Published var busy = false
    @Published var transferring = false
    @Published var progress = 0.0
    @Published var transfer = TransferSnapshot()
    @Published var showTransferDetails = false
    @Published var showCLI = false
    @Published var cliInstalled = CLIInstallation.isInstalled()
    @Published var deviceBusy = false
    @Published var cliMessage = ""
    @Published var status = L10n.text("Connect Your Android Device Using USB")
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var history: [String] = []
    @Published var breadcrumbs: [(id: UInt32, name: String)] = []
    @Published var showNewFolder = false
    @Published var folderName = ""
    @Published var dropTarget = false
    private let session = Session()
    private var transferControl: TransferControl?
    var connected: Bool { !storages.isEmpty }
    var parent: UInt32 { breadcrumbs.last?.id ?? UInt32.max }
    var storage: StorageInfo? { storages.first { $0.id == storageID } }
    var visibleItems: [RemoteItem] { items.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) } }
    var selectedItems: [RemoteItem] { items.filter { selection.contains($0.id) } }

    func log(_ message: String) {
        history.append("\(Date().formatted(date: .omitted, time: .standard))  \(message)")
        if history.count > 300 { history.removeFirst() }
    }
    private func fail(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        status = L10n.text("Couldn’t Complete the Operation")
        log(error.localizedDescription)
    }
    func scan() {
        guard !busy, !connected else { return }
        busy = true; status = L10n.text("Scanning for USB Devices…")
        Task {
            defer { busy = false }
            do {
                devices = try await session.detect()
                if !devices.contains(where: { $0.id == selectedDevice }) { selectedDevice = devices.first?.id ?? "" }
                status = devices.isEmpty ? L10n.text("No Android Devices Found") : L10n.text("Select a Device and Connect")
                log(L10n.text("devices.detected", devices.count))
            } catch { fail(error) }
        }
    }
    func connect() {
        guard !busy, !selectedDevice.isEmpty else { return }
        busy = true; status = L10n.text("Connecting to Device…")
        Task {
            defer { busy = false }
            do {
                let result = try await session.connect(selectedDevice)
                deviceName = result.0; storages = result.1
                storageID = storages[0].id; breadcrumbs = []; selection = []; search = ""
                try await reload()
                log(L10n.text("Connected: %@", deviceName))
            } catch {
                await session.disconnect()
                storages = []; items = []; deviceName = ""; fail(error)
            }
        }
    }
    func disconnect() {
        guard !busy else { return }
        busy = true
        Task {
            await session.disconnect()
            storages = []; items = []; selection = []; breadcrumbs = []; deviceName = ""; storageID = 0
            busy = false; status = L10n.text("USB Disconnected"); log(status)
            scan()
        }
    }
    private func reload() async throws {
        items = try await session.list(storage: storageID, parent: parent)
        selection = []; status = L10n.text("items.ready", items.count)
    }
    func refresh() {
        guard connected, !busy else { if !connected { scan() }; return }
        busy = true
        Task { defer { busy = false }; do { storages = try await session.storages(); try await reload() } catch { fail(error) } }
    }
    func navigate(_ item: RemoteItem) {
        guard item.isFolder, !busy else { return }
        let previous = breadcrumbs
        breadcrumbs.append((item.id, item.name)); search = ""; busy = true
        Task {
            defer { busy = false }
            do { try await reload() } catch { breadcrumbs = previous; fail(error) }
        }
    }
    func goTo(_ index: Int) {
        guard !busy else { return }
        let previous = breadcrumbs
        breadcrumbs = index < 0 ? [] : Array(breadcrumbs.prefix(index + 1)); search = ""; busy = true
        Task {
            defer { busy = false }
            do { try await reload() } catch { breadcrumbs = previous; fail(error) }
        }
    }
    func switchStorage(_ id: UInt32) {
        guard !busy, storageID != id else { return }
        let oldID = storageID, oldPath = breadcrumbs
        storageID = id; breadcrumbs = []; search = ""; busy = true
        Task {
            defer { busy = false }
            do { try await reload() } catch { storageID = oldID; breadcrumbs = oldPath; fail(error) }
        }
    }
    func chooseUpload() {
        guard connected, !busy else { return }
        let panel = NSOpenPanel()
        panel.title = L10n.text("Choose Files or Folders to Send to Android")
        panel.prompt = L10n.text("Send to Android"); panel.canChooseDirectories = true; panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { upload(panel.urls) }
    }
    func chooseDownload() {
        guard connected, !busy, !selectedItems.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.title = L10n.text("Choose a Folder on Your Mac"); panel.prompt = L10n.text("Save Here")
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url { download(to: url) }
    }
    private func beginTransfer() -> TransferControl {
        let control = TransferControl()
        control.onSnapshot = { [weak self] value in
            Task { @MainActor in
                if self?.transferring == true { self?.transfer = value; self?.progress = value.fraction }
            }
        }
        transferControl = control; busy = true; transferring = true; progress = 0; transfer = TransferSnapshot()
        return control
    }
    private var statusCallback: @Sendable (String) -> Void {
        { [weak self] value in Task { @MainActor in if self?.transferring == true { self?.status = value } } }
    }
    func upload(_ urls: [URL]) {
        guard connected, !busy, !urls.isEmpty else { return }
        let storage = storageID, folder = parent, control = beginTransfer(), callback = statusCallback
        log(L10n.text("upload.started", urls.count))
        Task {
            defer { busy = false; transferring = false; transferControl = nil }
            do {
                try await session.upload(urls, storage: storage, parent: folder, control: control, status: callback)
                transfer = control.snapshot
                storages = try await session.storages()
                try await reload(); status = L10n.text("upload.completed", urls.count); log(status)
            } catch {
                transfer = control.snapshot
                // Refresh after failure too, so any partial Android objects are visible.
                items = (try? await session.list(storage: storage, parent: folder)) ?? []
                fail(error)
            }
        }
    }
    func download(to url: URL) {
        let selected = selectedItems
        guard connected, !busy, !selected.isEmpty else { return }
        let storage = storageID, control = beginTransfer(), callback = statusCallback
        log(L10n.text("download.started", selected.count))
        Task {
            defer { busy = false; transferring = false; transferControl = nil }
            do {
                try await session.download(selected, storage: storage, to: url, control: control, status: callback)
                transfer = control.snapshot
                status = L10n.text("download.completed", selected.count); log(status)
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
            } catch { transfer = control.snapshot; fail(error) }
        }
    }
    func cancel() { transferControl?.cancel(); status = L10n.text("Canceling Transfer…") }
    func createFolder(_ name: String) {
        guard connected, !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                try await session.mkdir(name, storage: storageID, parent: parent)
                try await reload(); log(L10n.text("New Folder: %@", name))
            } catch { fail(error) }
        }
    }
    func showCLIInfo() {
        cliInstalled = CLIInstallation.isInstalled()
        deviceBusy = !selectedDevice.isEmpty && ((try? DeviceAccess.isBusy(id: selectedDevice)) ?? false)
        cliMessage = ""; showCLI = true
    }
    func installCLI() {
        do { try CLIInstallation.install(); cliInstalled = true; cliMessage = L10n.text("CLI Installed") }
        catch { cliMessage = error.localizedDescription }
    }
    func exportDiagnostics() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "MacAndFiles-diagnostics.txt"
        if panel.runModal() == .OK, let url = panel.url {
            let text = "\(AppInfo.name) \(AppInfo.version) (\(AppInfo.build))\n\(ProcessInfo.processInfo.operatingSystemVersionString)\nArchitecture: \(architecture)\nMTP backend: libmtp 1.1.23 / libusb 1.0.30\nDevices detected: \(devices.count)\n\n" + history.joined(separator: "\n")
            do { try text.write(to: url, atomically: true, encoding: .utf8) } catch { fail(error) }
        }
    }
    var architecture: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
}
