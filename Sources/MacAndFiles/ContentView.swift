import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    private let accent = Color.accentColor

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            VStack(spacing: 0) {
                if model.connected {
                    browser
                        .searchable(text: $model.search, isPresented: $model.searchPresented,
                                    placement: .toolbar, prompt: Text(L10n.text("Search Current Folder")))
                        .nativeSearchPresentation()
                } else { welcome }
                Divider()
                footer
            }
            .navigationTitle(model.connected ? model.deviceName : AppInfo.name)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    if model.connected {
                        Button { model.goTo(model.breadcrumbs.count - 2) } label: {
                            Label(L10n.text("Go Up"), systemImage: "arrow.up")
                        }
                        .help(L10n.text("Go Up (⌘↑)")).disabled(model.busy || model.breadcrumbs.isEmpty)
                    }
                }
                ToolbarItemGroup {
                    if model.connected {
                        Button { model.chooseUpload() } label: { Label(L10n.text("Send to Android"), systemImage: "arrow.up.doc") }
                            .help(L10n.text("Send to Android (⌘U)")).disabled(model.busy)
                        Button { model.chooseDownload() } label: { Label(L10n.text("Save to Mac"), systemImage: "arrow.down.doc") }
                            .help(L10n.text("Save Selected Items to Mac (⌘D)")).disabled(model.busy || model.selectedItems.isEmpty)
                    }
                }
                if #available(macOS 26, *), model.connected { ToolbarSpacer(.fixed) }
                ToolbarItemGroup {
                    if model.connected {
                        Button { model.folderName = ""; model.showNewFolder = true } label: { Label(L10n.text("New Folder"), systemImage: "folder.badge.plus") }
                            .help(L10n.text("New Folder (⌘⇧N)")).disabled(model.busy)
                    }
                    Button { model.refresh() } label: { Label(L10n.text("Refresh"), systemImage: "arrow.clockwise") }
                        .help(L10n.text("Scan for Devices or Refresh Folder (⌘R)")).disabled(model.busy)
                }
                ToolbarItem {
                    Menu {
                        if model.connected { Button(L10n.text("Disconnect"), systemImage: "eject") { model.disconnect() }.disabled(model.busy) }
                        Button(L10n.text("Terminal and Agents…"), systemImage: "terminal") { model.showCLIInfo() }
                        if model.transfer.totalFiles > 0 || !model.transfer.failures.isEmpty {
                            Button(L10n.text("Transfer Details…"), systemImage: "list.bullet.rectangle") { model.showTransferDetails = true }
                        }
                        Button(L10n.text("USB Connection Help"), systemImage: "questionmark.circle") { AppDelegate().showHelp() }
                        Button(L10n.text("Save Diagnostics…"), systemImage: "text.document") { model.exportDiagnostics() }
                    } label: { Label(L10n.text("More"), systemImage: "ellipsis.circle") }.help(L10n.text("Connection and Diagnostics"))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.layoutDirection, L10n.isRightToLeft ? .rightToLeft : .leftToRight)
        .onChange(of: model.search) { _, _ in
            // A hidden selection must not be downloaded after filtering the table.
            model.selection.formIntersection(model.visibleItems.map(\.id))
        }
        .onChange(of: model.connected) { _, connected in
            if !connected { model.search = ""; model.searchPresented = false }
        }
        .sheet(isPresented: $model.showCLI) { cliSheet }
        .sheet(isPresented: $model.showTransferDetails) { transferSheet }
        .sheet(isPresented: $model.showNewFolder) {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.text("Create a New Folder")).font(.headline)
                TextField(L10n.text("Folder Name"), text: $model.folderName).textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button(L10n.text("Cancel")) { model.showNewFolder = false }.keyboardShortcut(.cancelAction)
                    Button(L10n.text("Create")) { model.createFolder(model.folderName); model.showNewFolder = false }
                        .keyboardShortcut(.defaultAction).disabled(model.folderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }.padding(24).frame(width: 340)
        }
    }

    private var sidebar: some View {
        List(selection: Binding<UInt32?>(get: { model.connected ? model.storageID : nil }, set: { id in
            if let id { model.switchStorage(id) }
        })) {
            Section(L10n.text("Storage")) {
                if model.connected {
                    ForEach(model.storages) { storage in
                        Label(storage.name, systemImage: "internaldrive").tag(storage.id)
                    }
                } else {
                    Label(L10n.text("No Device Connected"), systemImage: "smartphone").foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar).scrollContentBackground(.hidden).disabled(model.busy)
        .safeAreaInset(edge: .bottom) {
            if let storage = model.storage, storage.capacity > 0 {
                VStack(alignment: .leading, spacing: 7) {
                    ProgressView(value: Double(storage.capacity - min(storage.free, storage.capacity)), total: Double(storage.capacity))
                    Text(L10n.text("%@ total · %@ available", bytes(storage.capacity), bytes(storage.free)))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.padding(16)
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 24)
            Image(systemName: "cable.connector").font(.system(size: 40, weight: .light)).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text(L10n.text("Connect Android")).font(.title2.weight(.semibold))
                Text(L10n.text("Connect using USB, unlock your device, then select\n“File Transfer / Android Auto” on your device."))
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if !model.devices.isEmpty {
                Picker(L10n.text("Device"), selection: $model.selectedDevice) {
                    ForEach(model.devices) { Text($0.name.isEmpty ? "Android" : $0.name).tag($0.id) }
                }.frame(maxWidth: 290).disabled(model.busy)
                Button(L10n.text("Connect")) { model.connect() }.nativeButton(prominent: true).disabled(model.busy)
            } else {
                Button(L10n.text("Scan for Devices")) { model.scan() }.nativeButton(prominent: false).disabled(model.busy)
            }
            Button(L10n.text("Connection Help")) { AppDelegate().showHelp() }.buttonStyle(.link).font(.caption)
            Spacer(minLength: 24)
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var pathBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                Button { model.goTo(-1) } label: { Label(model.storage?.name ?? L10n.text("Storage"), systemImage: "internaldrive") }
                    .help(L10n.text("Open Storage Root"))
                ForEach(Array(model.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                    Image(systemName: "chevron.forward").font(.system(size: 9)).foregroundStyle(.tertiary)
                    Button(crumb.name) { model.goTo(index) }.lineLimit(1).help(crumb.name)
                }
            }.buttonStyle(.plain).font(.callout).padding(.horizontal, 16).padding(.vertical, 9)
        }
        .scrollIndicators(.hidden).disabled(model.busy)
        .nativeGlass()
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
    private var browser: some View {
        VStack(spacing: 0) {
            pathBar
            Table(model.visibleItems, selection: $model.selection) {
                TableColumn(L10n.text("Name")) { item in
                    HStack(spacing: 10) {
                        Image(nsImage: FileIcons.image(for: item))
                            .resizable().scaledToFit().frame(width: 20, height: 20)
                        Text(item.name).lineLimit(1)
                    }
                        .padding(.vertical, 4)
                }.width(min: 200, ideal: 330)
                TableColumn(L10n.text("Size")) { item in Text(item.isFolder ? "—" : bytes(item.size)).foregroundStyle(.secondary) }.width(90)
                TableColumn(L10n.text("Date Modified")) { item in Text(item.modified.timeIntervalSince1970 <= 0 ? "—" : item.modified.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(.secondary) }.width(min: 120, ideal: 165)
            }
            .disabled(model.busy)
            .contextMenu(forSelectionType: UInt32.self) { ids in
                if ids.count == 1, let item = model.items.first(where: { ids.contains($0.id) }), item.isFolder {
                    Button(L10n.text("Open Folder")) { model.navigate(item) }.disabled(model.busy)
                }
                Button(L10n.text("Save to Mac…")) { model.selection = ids; model.chooseDownload() }.disabled(ids.isEmpty || model.busy)
            } primaryAction: { ids in
                if ids.count == 1, let item = model.items.first(where: { ids.contains($0.id) }) { model.navigate(item) }
            }
            .overlay {
                if model.visibleItems.isEmpty { ContentUnavailableView(model.search.isEmpty ? L10n.text("This Folder Is Empty") : L10n.text("No Search Results"), systemImage: "folder", description: Text(model.search.isEmpty ? L10n.text("Drop files here or choose “Send to Android” to copy them.") : L10n.text("Search matches file names in the current folder."))) }
                if model.dropTarget { RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 3).padding(5).allowsHitTesting(false) }
            }
            .onDrop(of: [.fileURL], isTargeted: $model.dropTarget) { providers in
                guard model.connected, !model.busy else { return false }
                Task { @MainActor in
                    var urls: [URL] = []
                    for provider in providers {
                        let url: URL? = await withCheckedContinuation { continuation in
                            _ = provider.loadObject(ofClass: NSURL.self) { value, _ in continuation.resume(returning: value as? URL) }
                        }
                        if let url { urls.append(url) }
                    }
                    model.upload(urls)
                }
                return true
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .nativeBackgroundExtension()
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if model.transferring {
                HStack {
                    ProgressView(value: model.progress)
                    Text(model.progress.formatted(.percent.precision(.fractionLength(0)))).font(.caption.monospacedDigit()).fixedSize()
                    Button(L10n.text("Cancel")) { model.cancel() }
                }
            }
            if model.transferring { transferSummary }
            HStack(spacing: 8) {
                if model.busy { ProgressView().controlSize(.mini) }
                Text(model.status).lineLimit(1).help(model.status)
                Spacer()
                if !model.transfer.failures.isEmpty {
                    Button(L10n.text("Transfer Details…")) { model.showTransferDetails = true }
                }
                if !model.search.isEmpty { Text(L10n.text("search.results", model.visibleItems.count)) }
                if !model.selection.isEmpty { Text(L10n.text("selection.count", model.selection.count)) }
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(.horizontal, 16).padding(.vertical, 9).background(.bar)
    }

    private var transferSummary: some View {
        HStack {
            Text(L10n.text("Files: %@ / %@", model.transfer.completedFiles.formatted(), model.transfer.totalFiles.formatted()))
            Text(L10n.text("%@ of %@", bytes(model.transfer.transferredBytes), bytes(model.transfer.totalBytes)))
            Spacer()
            if model.transfer.bytesPerSecond > 0 {
                Text(L10n.text("%@/s", bytes(UInt64(clamping: Int64(min(1e18, model.transfer.bytesPerSecond))))))
            }
            if let remaining = model.transfer.remainingSeconds {
                Text(L10n.text("About %@ remaining", duration(remaining)))
            }
        }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
    }
    private var transferSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("Transfer Details")).font(.title2)
            transferSummary
            ProgressView(value: model.transfer.fraction)
            if !model.transfer.failures.isEmpty {
                Text(L10n.text("Stopped at the first failure. Completed files are preserved; remaining files were not attempted.")).foregroundStyle(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(model.transfer.failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(failure.item).font(.headline).textSelection(.enabled)
                                Text(failure.message).textSelection(.enabled)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 240)
            }
            HStack { Spacer(); Button(L10n.text("Done")) { model.showTransferDetails = false }.keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 580)
    }
    private var cliSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("Terminal and Agents")).font(.title2)
            Text(model.cliInstalled ? L10n.text("CLI Installed") : L10n.text("CLI Not Installed")).font(.headline)
            Text(L10n.text("Use maf in a terminal. The installer adds maf and the aft compatibility alias to ~/.local/bin without changing your shell settings.")).foregroundStyle(.secondary)
            Text("maf devices\nmaf status\nmaf help").font(.system(.body, design: .monospaced)).textSelection(.enabled)
            Text(model.connected ? L10n.text("The app owns this USB connection. Disconnect before using the CLI.") : (model.deviceBusy ? L10n.text("Another MacAndFiles process owns this device.") : L10n.text("No MacAndFiles USB session is held by this app."))).foregroundStyle(.secondary)
            if !model.cliMessage.isEmpty { Text(model.cliMessage).textSelection(.enabled) }
            HStack {
                if model.connected { Button(L10n.text("Disconnect")) { model.disconnect(); model.deviceBusy = false }.disabled(model.busy) }
                Spacer()
                Button(L10n.text("Install CLI")) { model.installCLI() }
                Button(L10n.text("Done")) { model.showCLI = false }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 520)
    }
    private func duration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter(); formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: seconds) ?? "—"
    }

    private func bytes(_ n: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: n), countStyle: .file)
    }
}

/// Cache generic type icons without touching local or remote file contents.
@MainActor
private enum FileIcons {
    static var cache: [String: NSImage] = [:]
    static func image(for item: RemoteItem) -> NSImage {
        let ext = (item.name as NSString).pathExtension.lowercased()
        let key = item.isFolder ? "<folder>" : ext
        if let cached = cache[key] { return cached }
        let type: UTType = item.isFolder ? .folder : (UTType(filenameExtension: ext) ?? .data)
        let icon = NSWorkspace.shared.icon(for: type)
        // Bound memory use for devices containing many unusual extensions.
        if cache.count >= 256 { cache.removeAll(keepingCapacity: true) }
        cache[key] = icon
        return icon
    }
}
