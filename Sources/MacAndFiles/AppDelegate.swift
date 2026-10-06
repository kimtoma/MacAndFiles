import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model, model.busy else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = L10n.text("An Operation Is in Progress")
        alert.informativeText = model.transferring ? L10n.text("Cancel the transfer and wait for it to finish before quitting.") : L10n.text("Wait for the USB operation to finish before quitting.")
        alert.addButton(withTitle: L10n.text("Keep Waiting"))
        if model.transferring { alert.addButton(withTitle: L10n.text("Cancel Transfer")) }
        if alert.runModal() == .alertSecondButtonReturn { model.cancel() }
        return .terminateCancel
    }
    func showHelp() {
        let alert = NSAlert()
        alert.messageText = L10n.text("Android USB Connection")
        alert.informativeText = L10n.text("help.usb")
        alert.runModal()
    }
}
