import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
enum Launcher {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--probe") || CommandLine.arguments.contains("--verify-transfer") {
            do {
                let result = try DeviceVerification.run(roundTrip: CommandLine.arguments.contains("--verify-transfer"))
                let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
                print(String(decoding: data, as: UTF8.self))
                if let index = CommandLine.arguments.firstIndex(of: "--report"), CommandLine.arguments.count > index + 1 {
                    try data.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]), options: .atomic)
                }
                exit(0)
            } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
        }
        if CommandLine.arguments.contains("--diagnose") {
            let mtp = MTPTransport()
            do {
                let devices = try mtp.detect()
                let report: [String: Any] = ["app": AppInfo.name, "version": AppInfo.version, "build": AppInfo.build,
                    "os": ProcessInfo.processInfo.operatingSystemVersionString,
                    "backend": "libmtp 1.1.23 / libusb 1.0.30",
                    "devices": devices.map { ["id": $0.id, "name": $0.name] }]
                let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                print(String(decoding: data, as: UTF8.self))
                exit(0)
            } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
        }
        if CommandLine.arguments.count > 1 { CLIRunner.run(Array(CommandLine.arguments.dropFirst())) }
        MacAndFilesApp.main()
    }
}

struct MacAndFilesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel()
    var body: some Scene {
        Window(AppInfo.name, id: "main") {
            ContentView(model: model)
                .frame(minWidth: 800, minHeight: 500)
                .task { delegate.model = model; model.scan() }
                .alert(L10n.text("Couldn’t Complete the Operation"), isPresented: $model.showError) {
                    Button(L10n.text("OK"), role: .cancel) { }
                } message: { Text(model.errorMessage ?? L10n.text("Unknown Error")) }
        }
        .defaultSize(width: 1000, height: 660)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button(L10n.text("New Folder…")) { model.folderName = ""; model.showNewFolder = true }
                    .keyboardShortcut("n", modifiers: [.command, .shift]).disabled(!model.connected || model.busy)
                Button(L10n.text("Send to Android…")) { model.chooseUpload() }.keyboardShortcut("u").disabled(!model.connected || model.busy)
                Button(L10n.text("Save to Mac…")) { model.chooseDownload() }.keyboardShortcut("d").disabled(model.selectedItems.isEmpty || model.busy)
            }
            CommandGroup(after: .toolbar) {
                Button(L10n.text("Go Up")) { model.goTo(model.breadcrumbs.count - 2) }
                    .keyboardShortcut(.upArrow, modifiers: .command).disabled(!model.connected || model.busy || model.breadcrumbs.isEmpty)
                Button(L10n.text("Refresh")) { model.refresh() }.keyboardShortcut("r").disabled(model.busy)
                Button(L10n.text("Terminal and Agents…")) { model.showCLIInfo() }
                Button(L10n.text("Save Diagnostics…")) { model.exportDiagnostics() }
            }
            CommandGroup(after: .textEditing) {
                Button(L10n.text("Search Current Folder")) { model.searchPresented = true }
                    .keyboardShortcut("f").disabled(!model.connected)
            }
            CommandGroup(replacing: .help) {
                Button(L10n.text("USB Connection Help")) { delegate.showHelp() }
            }
        }
    }
}
