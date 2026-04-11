//
//  ContentView.swift
//  OpenBox
//
//  Created by jianliang on 2026/1/24.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingPullImage = false
    @State private var showingCreateSandbox = false
    @State private var createSandboxReference: String?
    @State private var runWorkloadTarget: SandboxRecord?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $appState.selectedSidebar)
                .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } content: {
            switch appState.selectedSidebar {
            case .sandboxes:
                SandboxListView(showCreateSandbox: $showingCreateSandbox)
            case .images:
                ImageListView(
                    showPullImage: $showingPullImage,
                    onCreateSandbox: { reference in
                        createSandboxReference = reference
                        showingCreateSandbox = true
                    }
                )
            case .settings:
                SettingsSummaryView()
            }
        } detail: {
            DetailColumnView(
                showCreateSandbox: $showingCreateSandbox,
                createSandboxReference: $createSandboxReference,
                runWorkloadTarget: $runWorkloadTarget
            )
        }
        .task {
            await appState.refreshAllIfNeeded()
        }
        .sheet(isPresented: $showingPullImage) {
            PullImageSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingCreateSandbox, onDismiss: {
            createSandboxReference = nil
        }) {
            CreateSandboxSheet(initialImageReference: createSandboxReference)
                .environmentObject(appState)
        }
        .sheet(item: $runWorkloadTarget) { sandbox in
            RunWorkloadSheet(sandbox: sandbox)
                .environmentObject(appState)
        }
        .safeAreaInset(edge: .top) {
            if let banner = appState.banner {
                BannerView(banner: banner) {
                    appState.clearBanner()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let activityMessage = appState.activityMessage {
                ActivityBubble(message: activityMessage)
                    .padding(20)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await appState.refreshAll()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isRefreshing || appState.isMutating)

                switch appState.selectedSidebar {
                case .sandboxes:
                    Button {
                        createSandboxReference = nil
                        showingCreateSandbox = true
                    } label: {
                        Label("New Sandbox", systemImage: "plus.circle.fill")
                    }
                    .disabled(appState.isMutating)
                case .images:
                    Button {
                        showingPullImage = true
                    } label: {
                        Label("Pull Image", systemImage: "arrow.down.circle.fill")
                    }
                    .disabled(appState.isMutating)
                case .settings:
                    EmptyView()
                }
            }
        }
        .font(AppTheme.bodyFont)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarSection

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.iconName)
                .tag(section)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }
}

struct SandboxListView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showCreateSandbox: Bool

    @State private var searchText = ""

    private var filteredSandboxes: [SandboxRecord] {
        guard !searchText.isEmpty else { return appState.sandboxes }
        return appState.sandboxes.filter { sandbox in
            sandbox.name.localizedCaseInsensitiveContains(searchText) ||
            sandbox.imageReference.localizedCaseInsensitiveContains(searchText) ||
            sandbox.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SearchField(title: "Search sandboxes", text: $searchText)
                    .frame(minWidth: 180)
                Button {
                    showCreateSandbox = true
                } label: {
                    Label("New Sandbox", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isMutating)
            }
            .padding(.horizontal)

            if !appState.systemStatus.isAvailable {
                ServiceUnavailableView(message: appState.systemStatus.lastError)
                    .padding(.horizontal)
                Spacer()
            } else if filteredSandboxes.isEmpty {
                EmptyStateView(
                    title: "No sandboxes",
                    message: "Create a sandbox from an OCI image to start managing runtimes through the container SDK."
                )
            } else {
                List {
                    ForEach(filteredSandboxes) { sandbox in
                        Button {
                            appState.selectedSandboxID = sandbox.id
                        } label: {
                            SandboxRow(sandbox: sandbox)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            appState.selectedSandboxID == sandbox.id ? AppTheme.highlight.opacity(0.45) : Color.clear
                        )
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 460)
        .padding(.top, 12)
    }
}

struct ImageListView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showPullImage: Bool

    let onCreateSandbox: (String) -> Void

    @State private var searchText = ""

    private var filteredImages: [OCIImageRecord] {
        guard !searchText.isEmpty else { return appState.images }
        return appState.images.filter { image in
            image.reference.localizedCaseInsensitiveContains(searchText) ||
            image.digest.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SearchField(title: "Search images", text: $searchText)
                    .frame(minWidth: 180)
                Button {
                    showPullImage = true
                } label: {
                    Label("Pull Image", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isMutating)
            }
            .padding(.horizontal)

            if !appState.systemStatus.isAvailable {
                ServiceUnavailableView(message: appState.systemStatus.lastError)
                    .padding(.horizontal)
                Spacer()
            } else if filteredImages.isEmpty {
                EmptyStateView(
                    title: "No local images",
                    message: "Pull an OCI image reference directly from a registry and it will appear here."
                )
            } else {
                List {
                    ForEach(filteredImages) { image in
                        Button {
                            appState.selectedImageReference = image.reference
                        } label: {
                            ImageRow(image: image)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Create Sandbox") {
                                onCreateSandbox(image.reference)
                            }
                            Button("Delete Image", role: .destructive) {
                                appState.deleteImage(reference: image.reference)
                            }
                        }
                        .listRowBackground(
                            appState.selectedImageReference == image.reference ? AppTheme.highlight.opacity(0.45) : Color.clear
                        )
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationSplitViewColumnWidth(min: 340, ideal: 460, max: 520)
        .padding(.top, 12)
    }
}

struct SettingsSummaryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("System")
                    .font(AppTheme.titleFont)
                SettingsCard(
                    title: "Runtime Contract",
                    detail: "OpenBox now talks directly to the container SDK. The container services must already be installed and running."
                )
                SettingsCard(
                    title: "Image Flow",
                    detail: "OCI image references are pulled directly through the SDK. There is no IPSW download, restore image cache, or local image preparation step anymore."
                )
                SettingsCard(
                    title: "Current Status",
                    detail: appState.systemStatus.isAvailable
                        ? "Connected to container services."
                        : (appState.systemStatus.lastError ?? "Container services are unavailable.")
                )
            }
            .padding(24)
        }
    }
}

struct DetailColumnView: View {
    @EnvironmentObject private var appState: AppState

    @Binding var showCreateSandbox: Bool
    @Binding var createSandboxReference: String?
    @Binding var runWorkloadTarget: SandboxRecord?

    var body: some View {
        switch appState.selectedSidebar {
        case .sandboxes:
            if let sandbox = appState.selectedSandbox {
                SandboxDetailView(
                    sandbox: sandbox,
                    detail: appState.selectedSandboxDetail,
                    onRunCommand: {
                        runWorkloadTarget = sandbox
                    }
                )
            } else {
                EmptyDetailView(
                    title: "Select a sandbox",
                    message: "Sandbox configuration, workloads, logs, and network details appear here."
                )
            }
        case .images:
            if let image = appState.selectedImage {
                ImageDetailView(
                    image: image,
                    onCreateSandbox: {
                        createSandboxReference = image.reference
                        showCreateSandbox = true
                    }
                )
            } else {
                EmptyDetailView(
                    title: "Select an image",
                    message: "Inspect local OCI images and create sandboxes directly from them."
                )
            }
        case .settings:
            SettingsDetailView()
        }
    }
}

struct SandboxRow: View {
    let sandbox: SandboxRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(sandbox.name)
                    .font(AppTheme.sectionTitleFont)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: sandbox.status.label, color: sandbox.status.color)
            }
            Text(sandbox.imageReference)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack(spacing: 12) {
                StatusPill(text: sandbox.platform, color: AppTheme.warning)
                StatusPill(text: "\(sandbox.cpuCores) CPU", color: AppTheme.accent)
                StatusPill(text: "\(sandbox.memoryGB) GB RAM", color: AppTheme.highlight)
                if let diskGB = sandbox.diskGB {
                    StatusPill(text: "\(diskGB) GB Disk", color: AppTheme.highlight)
                }
                if sandbox.workloadCount > 0 {
                    StatusPill(text: "\(sandbox.workloadCount) Workloads", color: AppTheme.warning)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct ImageRow: View {
    let image: OCIImageRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(image.reference)
                .font(AppTheme.sectionTitleFont)
                .lineLimit(2)
            HStack(spacing: 12) {
                StatusPill(text: image.shortDigest, color: AppTheme.accent)
                Text(image.mediaType)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SandboxDetailView: View {
    @EnvironmentObject private var appState: AppState

    let sandbox: SandboxRecord
    let detail: SandboxDetail?
    let onRunCommand: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !appState.systemStatus.isAvailable {
                    ServiceUnavailableView(message: appState.systemStatus.lastError)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(sandbox.name)
                                .font(AppTheme.titleFont)
                            Text(sandbox.id)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        StatusBadge(text: sandbox.status.label, color: sandbox.status.color)
                    }

                    HStack(spacing: 12) {
                        Button(sandbox.status.isRunning ? "Stop Sandbox" : "Start Sandbox") {
                            appState.toggleSandbox(sandbox.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isMutating || sandbox.status == .creating || sandbox.status == .pulling)

                        Button("Run Command") {
                            onRunCommand()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!sandbox.status.isRunning || appState.isMutating)

                        Button("Remove Sandbox", role: .destructive) {
                            appState.removeSandbox(sandbox.id)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.isMutating)
                    }
                }
                .padding(18)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                InfoCard(title: "Configuration") {
                    PropertyRow(label: "OCI Image", value: sandbox.imageReference)
                    PropertyRow(label: "Digest", value: sandbox.imageDigest)
                    PropertyRow(label: "Runtime", value: sandbox.runtimeHandler)
                    PropertyRow(label: "Platform", value: sandbox.platform)
                    PropertyRow(label: "Resources", value: "\(sandbox.cpuCores) CPU / \(sandbox.memoryGB) GB RAM / \(sandbox.diskGB.map(String.init) ?? "—") GB Disk")
                    PropertyRow(label: "Workspace", value: sandbox.workspacePath ?? "Not mounted")
                    PropertyRow(label: "Share Mode", value: sandbox.shareMode?.label ?? "—")
                    PropertyRow(label: "Started", value: sandbox.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                }

                if let lastError = sandbox.lastError ?? detail?.lastError {
                    InfoCard(title: "Last Error") {
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
                            .textSelection(.enabled)
                    }
                }

                InfoCard(title: "Networks") {
                    if let detail, !detail.networks.isEmpty {
                        ForEach(detail.networks) { network in
                            Divider()
                                .opacity(network.id == detail.networks.first?.id ? 0 : 1)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(network.networkID)
                                    .font(AppTheme.sectionTitleFont)
                                PropertyRow(label: "Hostname", value: network.hostname)
                                PropertyRow(label: "IPv4", value: network.ipv4Address)
                                PropertyRow(label: "Gateway", value: network.gateway)
                                PropertyRow(label: "DNS", value: network.dnsServers.joined(separator: ", ").ifEmpty("—"))
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No network attachments reported for this sandbox.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                InfoCard(title: "Logs") {
                    if let logPaths = detail?.logPaths {
                        PathBlock(title: "Event Log", path: logPaths.eventLogPath)
                        PathBlock(title: "Boot Log", path: logPaths.bootLogPath)
                        PathBlock(title: "Guest Agent STDOUT", path: logPaths.guestAgentLogPath)
                        PathBlock(title: "Guest Agent STDERR", path: logPaths.guestAgentStderrLogPath)
                    } else {
                        Text("No sandbox log paths were returned.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                InfoCard(title: "Workloads") {
                    if let detail, !detail.workloads.isEmpty {
                        ForEach(detail.workloads) { workload in
                            WorkloadCard(
                                sandboxID: sandbox.id,
                                workload: workload
                            )
                        }
                    } else {
                        Text("No workloads have been started in this sandbox yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct WorkloadCard: View {
    @EnvironmentObject private var appState: AppState

    let sandboxID: String
    let workload: WorkloadRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(workload.command)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                    .textSelection(.enabled)
                Spacer()
                StatusBadge(text: workload.status.label, color: workload.status.color)
            }

            PropertyRow(label: "Working Dir", value: workload.workingDirectory)
            PropertyRow(label: "Image-backed", value: workload.isImageBacked ? "Yes" : "No")
            PropertyRow(label: "Started", value: workload.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
            PropertyRow(label: "Exited", value: workload.exitedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
            PropertyRow(label: "Exit Code", value: workload.exitCode.map(String.init) ?? "—")
            PathBlock(title: "STDOUT", path: workload.stdoutLogPath)
            PathBlock(title: "STDERR", path: workload.stderrLogPath)

            HStack(spacing: 12) {
                if workload.status == .running {
                    Button("Stop Workload") {
                        appState.stopWorkload(sandboxID: sandboxID, workloadID: workload.id)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isMutating)
                }

                if workload.status != .running {
                    Button("Remove Workload", role: .destructive) {
                        appState.removeWorkload(sandboxID: sandboxID, workloadID: workload.id)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isMutating)
                }
            }
        }
        .padding(14)
        .background(AppTheme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ImageDetailView: View {
    @EnvironmentObject private var appState: AppState

    let image: OCIImageRecord
    let onCreateSandbox: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !appState.systemStatus.isAvailable {
                    ServiceUnavailableView(message: appState.systemStatus.lastError)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(image.reference)
                        .font(AppTheme.titleFont)
                    HStack(spacing: 10) {
                        StatusBadge(text: image.shortDigest, color: AppTheme.accent)
                        Text(image.mediaType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        Button("Create Sandbox") {
                            onCreateSandbox()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isMutating)

                        Button("Delete Image", role: .destructive) {
                            appState.deleteImage(reference: image.reference)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.isMutating)
                    }
                }
                .padding(18)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                InfoCard(title: "Reference") {
                    PropertyRow(label: "OCI Reference", value: image.reference)
                    PropertyRow(label: "Digest", value: image.digest)
                    PropertyRow(label: "Media Type", value: image.mediaType)
                }

                InfoCard(title: "Usage") {
                    Text("Use this image directly in a new sandbox. If you enter the same reference in the sandbox wizard, OpenBox will reuse the local image instead of rebuilding or preparing anything.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("System Settings")
                    .font(AppTheme.titleFont)

                InfoCard(title: "Container Services") {
                    PropertyRow(label: "Connected", value: appState.systemStatus.isAvailable ? "Yes" : "No")
                    PropertyRow(label: "Version", value: appState.systemStatus.version ?? "—")
                    PropertyRow(label: "Build", value: appState.systemStatus.build ?? "—")
                    PropertyRow(label: "App Root", value: appState.systemStatus.appRoot ?? "—")
                    PropertyRow(label: "Install Root", value: appState.systemStatus.installRoot ?? "—")
                    if let lastError = appState.systemStatus.lastError {
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
                            .textSelection(.enabled)
                    }
                }

                InfoCard(title: "Runtime Notes") {
                    Text("OpenBox only embeds the client SDK surface. It does not install or bootstrap the container services. If connection fails, make sure the container runtime is already installed and running, for example via `container system start`.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }

                InfoCard(title: "Refactor Result") {
                    Text("The old restore-image, IPSW, VNC, and VM bundle preparation path has been removed. New sandboxes are created straight from OCI images pulled through the container SDK.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
    }
}

struct PullImageSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ImagePullDraft()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Pull OCI Image")
                .font(AppTheme.titleFont)

            Form {
                TextField("ghcr.io/org/image:tag", text: $draft.reference)
                Text("The image reference is sent directly to the container SDK. No local conversion or preparation step is used.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Pull") {
                    let reference = draft.reference
                    dismiss()
                    Task { @MainActor in
                        appState.pullImage(reference: reference)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

struct CreateSandboxSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SandboxDraft
    @State private var showFolderPicker = false

    init(initialImageReference: String? = nil) {
        _draft = State(initialValue: SandboxDraft(
            name: "OpenBox Sandbox",
            imageReference: initialImageReference ?? "",
            cpuCores: 4,
            memoryGB: 8,
            diskGB: 60,
            workspacePath: "",
            shareMode: .readWrite,
            autoStart: true
        ))
    }

    private var canSubmit: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draft.imageReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create Sandbox")
                .font(AppTheme.titleFont)

            Form {
                TextField("Sandbox name", text: $draft.name)
                TextField("OCI image reference", text: $draft.imageReference)

                Stepper("CPU Cores: \(draft.cpuCores)", value: $draft.cpuCores, in: 2...12)
                Stepper("Memory: \(draft.memoryGB) GB", value: $draft.memoryGB, in: 4...64, step: 2)
                Stepper("Disk: \(draft.diskGB) GB", value: $draft.diskGB, in: 20...256, step: 10)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Host workspace (optional)", text: $draft.workspacePath)
                        Button("Choose Folder") {
                            showFolderPicker = true
                        }
                    }
                    Picker("Share Mode", selection: $draft.shareMode) {
                        ForEach(FileShareMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("If the image is not local yet, OpenBox will pull it from the OCI registry before creating the sandbox.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Toggle("Create and start immediately", isOn: $draft.autoStart)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Create") {
                    let submittedDraft = draft
                    dismiss()
                    Task { @MainActor in
                        appState.createSandbox(from: submittedDraft)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding(24)
        .frame(width: 620)
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                draft.workspacePath = url.path
            }
        }
    }
}

struct RunWorkloadSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let sandbox: SandboxRecord

    @State private var shellCommand: String
    @State private var workingDirectory: String

    init(sandbox: SandboxRecord) {
        self.sandbox = sandbox
        _shellCommand = State(initialValue: sandbox.isMacOSGuest ? "sw_vers" : "uname -a")
        _workingDirectory = State(initialValue: sandbox.workspacePath == nil ? "/" : sandbox.guestWorkspacePath)
    }

    private var canSubmit: Bool {
        !shellCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Run Command")
                .font(AppTheme.titleFont)

            Form {
                Text("Sandbox: \(sandbox.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Shell command", text: $shellCommand)
                TextField("Working directory", text: $workingDirectory)
                Text("Commands run as `\(sandbox.shellPath) -lc <command>` inside the sandbox.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Run") {
                    let submittedDraft = WorkloadDraft(
                        sandboxID: sandbox.id,
                        shellCommand: shellCommand,
                        workingDirectory: workingDirectory
                    )
                    dismiss()
                    Task { @MainActor in
                        appState.runWorkload(submittedDraft)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}

struct ServiceUnavailableView: View {
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Container services unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(AppTheme.sectionTitleFont)
                .foregroundColor(AppTheme.danger)
            Text(message ?? "OpenBox could not reach the container services.")
                .font(.caption)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            Text("Make sure the container runtime is already installed and started before using this app.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyDetailView: View {
    let title: String
    let message: String

    var body: some View {
        EmptyStateView(title: title, message: message)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(AppTheme.titleFont)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTheme.sectionTitleFont)
            content
        }
        .padding(18)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SettingsCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.sectionTitleFont)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PropertyRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.caption)
    }
}

struct PathBlock: View {
    let title: String
    let path: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            if let path, !path.isEmpty {
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundColor(.primary)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SearchField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(title, text: $text)
        }
        .padding(8)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.22))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct BannerView: View {
    let banner: AppBanner
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: banner.style == .error ? "xmark.octagon.fill" : "info.circle.fill")
                .foregroundColor(banner.style.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(AppTheme.sectionTitleFont)
                Text(banner.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 3)
    }
}

struct ActivityBubble: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(message)
                .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.panel)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 3)
    }
}

enum AppTheme {
    static let background = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
        }
        return NSColor(calibratedRed: 0.96, green: 0.95, blue: 0.92, alpha: 1.0)
    })

    static let panel = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
        }
        return NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1.0)
    })

    static let accent = Color(red: 0.07, green: 0.50, blue: 0.44)
    static let highlight = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(calibratedRed: 0.36, green: 0.32, blue: 0.26, alpha: 1.0)
        }
        return NSColor(calibratedRed: 0.93, green: 0.87, blue: 0.74, alpha: 1.0)
    })
    static let warning = Color(red: 0.84, green: 0.52, blue: 0.28)
    static let danger = Color(red: 0.78, green: 0.28, blue: 0.22)
    static let bodyFont = Font.custom("Avenir Next", size: 13)
    static let sectionTitleFont = Font.custom("Avenir Next", size: 14).weight(.semibold)
    static let titleFont = Font.custom("Avenir Next", size: 20).weight(.semibold)
}

extension SidebarSection {
    var iconName: String {
        switch self {
        case .sandboxes:
            return "cube.box.fill"
        case .images:
            return "shippingbox.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

extension SandboxStatus {
    var label: String {
        switch self {
        case .pulling:
            return "Pulling"
        case .creating:
            return "Creating"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .stopping:
            return "Stopping"
        case .stopped:
            return "Stopped"
        case .error:
            return "Error"
        case .unknown:
            return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .pulling, .creating, .starting:
            return AppTheme.highlight
        case .running:
            return AppTheme.accent
        case .stopping:
            return AppTheme.warning
        case .stopped, .unknown:
            return .secondary
        case .error:
            return AppTheme.danger
        }
    }

    var isRunning: Bool {
        self == .running
    }
}

extension WorkloadStatus {
    var label: String {
        switch self {
        case .running:
            return "Running"
        case .stopping:
            return "Stopping"
        case .stopped:
            return "Stopped"
        case .unknown:
            return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .running:
            return AppTheme.accent
        case .stopping:
            return AppTheme.warning
        case .stopped:
            return .secondary
        case .unknown:
            return AppTheme.highlight
        }
    }
}

extension BannerStyle {
    var color: Color {
        switch self {
        case .info:
            return AppTheme.accent
        case .error:
            return AppTheme.danger
        }
    }
}

extension OCIImageRecord {
    var shortDigest: String {
        digest.count > 18 ? String(digest.prefix(18)) + "…" : digest
    }
}

extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
