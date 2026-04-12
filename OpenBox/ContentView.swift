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
                onRunCommand: { sandbox in
                    runWorkloadTarget = sandbox
                }
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
    @State private var expandedSandboxIDs: Set<String> = []

    private var filteredSandboxes: [SandboxRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return appState.sandboxes }
        return appState.sandboxes.filter { sandbox in
            sandboxMatches(sandbox, query: query) ||
            workloads(for: sandbox).contains { workloadMatches($0, query: query) }
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredSandboxes) { sandbox in
                            let visibleWorkloads = displayedWorkloads(for: sandbox)
                            let isExpanded = expandedSandboxIDs.contains(sandbox.id) || !searchText.isEmpty

                            SandboxTreeSandboxRow(
                                sandbox: sandbox,
                                workloadCount: workloads(for: sandbox).count,
                                isExpanded: isExpanded,
                                isSelected: appState.selectedSandboxID == sandbox.id && appState.selectedWorkloadID == nil,
                                onTap: {
                                    appState.selectedSandboxID = sandbox.id
                                    appState.selectedWorkloadID = nil
                                    toggleExpansion(for: sandbox)
                                }
                            )

                            if isExpanded {
                                if visibleWorkloads.isEmpty {
                                    Text("No workloads")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 44)
                                        .padding(.vertical, 6)
                                } else {
                                    ForEach(visibleWorkloads) { workload in
                                        SandboxTreeWorkloadRow(
                                            workload: workload,
                                            isSelected: appState.selectedSandboxID == sandbox.id && appState.selectedWorkloadID == workload.id,
                                            onTap: {
                                                appState.selectedSandboxID = sandbox.id
                                                appState.selectedWorkloadID = workload.id
                                                expandedSandboxIDs.insert(sandbox.id)
                                            }
                                        )
                                        .padding(.leading, 32)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 500)
        .padding(.top, 12)
        .onAppear {
            if let selectedSandboxID = appState.selectedSandboxID {
                expandedSandboxIDs.insert(selectedSandboxID)
            }
        }
        .onChange(of: appState.selectedSandboxID) { _, selectedSandboxID in
            if let selectedSandboxID {
                expandedSandboxIDs.insert(selectedSandboxID)
            }
        }
    }

    private func workloads(for sandbox: SandboxRecord) -> [WorkloadRecord] {
        appState.sandboxDetails[sandbox.id]?.workloads ?? []
    }

    private func displayedWorkloads(for sandbox: SandboxRecord) -> [WorkloadRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !sandboxMatches(sandbox, query: query) else {
            return workloads(for: sandbox)
        }
        return workloads(for: sandbox).filter { workloadMatches($0, query: query) }
    }

    private func sandboxMatches(_ sandbox: SandboxRecord, query: String) -> Bool {
        sandbox.name.localizedCaseInsensitiveContains(query) ||
        sandbox.imageReference.localizedCaseInsensitiveContains(query) ||
        sandbox.id.localizedCaseInsensitiveContains(query)
    }

    private func workloadMatches(_ workload: WorkloadRecord, query: String) -> Bool {
        workload.command.localizedCaseInsensitiveContains(query) ||
        workload.workingDirectory.localizedCaseInsensitiveContains(query) ||
        workload.id.localizedCaseInsensitiveContains(query)
    }

    private func toggleExpansion(for sandbox: SandboxRecord) {
        if expandedSandboxIDs.contains(sandbox.id) {
            expandedSandboxIDs.remove(sandbox.id)
        } else {
            expandedSandboxIDs.insert(sandbox.id)
        }
    }
}

struct SandboxTreeSandboxRow: View {
    let sandbox: SandboxRecord
    let workloadCount: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                sandboxLabel

                HStack(spacing: 8) {
                    Circle()
                        .fill(sandbox.status.color)
                        .frame(width: 6, height: 6)

                    Text(sandbox.status.label)
                        .foregroundColor(sandbox.status.color)

                    if workloadCount > 0 {
                        Text("\(workloadCount) \(workloadCount == 1 ? "workload" : "workloads")")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption2)
                .lineLimit(1)
                .padding(.leading, 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppTheme.highlight.opacity(0.42) : Color.clear)
        )
    }

    private var sandboxLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 12)

            Image(systemName: "folder")
                .foregroundColor(.secondary)
                .frame(width: 18)

            Text(sandbox.name)
                .font(AppTheme.sectionTitleFont)
                .lineLimit(1)
                .truncationMode(.middle)
                .layoutPriority(1)
        }
        .contentShape(Rectangle())
    }
}

struct SandboxTreeWorkloadRow: View {
    let workload: WorkloadRecord
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: workload.status == .running ? "terminal.fill" : "terminal")
                    .foregroundColor(workload.status == .running ? AppTheme.accent : .secondary)
                    .frame(width: 18)

                Text(workload.command)
                    .font(AppTheme.sectionTitleFont)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(workload.startedAt?.compactRelativeDescription ?? workload.status.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppTheme.highlight.opacity(0.42) : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
    let onRunCommand: (SandboxRecord) -> Void

    var body: some View {
        switch appState.selectedSidebar {
        case .sandboxes:
            if let sandbox = appState.selectedSandbox {
                SandboxDetailView(
                    sandbox: sandbox,
                    detail: appState.selectedSandboxDetail,
                    selectedWorkload: appState.selectedWorkload,
                    onRunCommand: onRunCommand
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
    let selectedWorkload: WorkloadRecord?
    let onRunCommand: (SandboxRecord) -> Void

    private var runningWorkloadIDs: [String] {
        detail?.workloads
            .filter { $0.status == .running }
            .map(\.id) ?? []
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !appState.systemStatus.isAvailable {
                        ServiceUnavailableView(message: appState.systemStatus.lastError)
                    }

                    if let selectedWorkload {
                        WorkloadDetailView(
                            sandbox: sandbox,
                            workload: selectedWorkload,
                            viewportHeight: proxy.size.height
                        )
                    } else {
                        SandboxSummaryCard(
                            sandbox: sandbox,
                            detail: detail,
                            onRunCommand: {
                                onRunCommand(sandbox)
                            }
                        )
                    }
                }
                .padding(24)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: runningWorkloadIDs) {
            guard !runningWorkloadIDs.isEmpty else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                await appState.refreshSandbox(id: sandbox.id)
            }
        }
    }
}

struct SandboxSummaryCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingRemoveConfirmation = false

    let sandbox: SandboxRecord
    let detail: SandboxDetail?
    let onRunCommand: () -> Void

    private var toggleSandboxTitle: String {
        sandbox.status.isRunning ? "Stop Sandbox" : "Start Sandbox"
    }

    private var toggleSandboxIcon: String {
        sandbox.status.isRunning ? "stop.fill" : "play.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sandbox.name)
                        .font(AppTheme.titleFont)
                        .lineLimit(2)
                    Text(sandbox.id)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                Spacer()
                StatusBadge(text: sandbox.status.label, color: sandbox.status.color)
            }

            HStack(spacing: 8) {
                Button {
                    onRunCommand()
                } label: {
                    Label("Run Command", systemImage: "terminal")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(AppTheme.accent)
                .disabled(!sandbox.status.isRunning || appState.isMutating)
                .help("Run Command")

                Button {
                    appState.toggleSandbox(sandbox.id)
                } label: {
                    Label(toggleSandboxTitle, systemImage: toggleSandboxIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(sandbox.status.isRunning ? AppTheme.danger : AppTheme.accent)
                .disabled(appState.isMutating || sandbox.status == .creating || sandbox.status == .pulling)
                .help(toggleSandboxTitle)

                Spacer()
            }
            .font(.caption)

            Divider()

            SandboxDetailSection(title: "Configuration") {
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
                Divider()
                SandboxDetailSection(title: "Last Error") {
                    Text(lastError)
                        .font(.caption)
                        .foregroundColor(AppTheme.danger)
                        .textSelection(.enabled)
                }
            }

            Divider()

            SandboxDetailSection(title: "Networks") {
                if let detail, !detail.networks.isEmpty {
                    ForEach(detail.networks) { network in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(network.networkID)
                                .font(AppTheme.sectionTitleFont)
                            PropertyRow(label: "Hostname", value: network.hostname)
                            PropertyRow(label: "IPv4", value: network.ipv4Address)
                            PropertyRow(label: "Gateway", value: network.gateway)
                            PropertyRow(label: "DNS", value: network.dnsServers.joined(separator: ", ").ifEmpty("—"))
                        }
                        .padding(.vertical, 4)

                        if network.id != detail.networks.last?.id {
                            Divider()
                        }
                    }
                } else {
                    Text("No network attachments reported for this sandbox.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            SandboxDetailSection(title: "Logs") {
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

            Divider()

            HStack {
                Spacer()
                Button(role: .destructive) {
                    showingRemoveConfirmation = true
                } label: {
                    Label("Remove Sandbox", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(AppTheme.danger)
                .disabled(appState.isMutating)
            }
        }
        .padding(18)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .alert("Remove Sandbox?", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove Sandbox", role: .destructive) {
                appState.removeSandbox(sandbox.id)
            }
        } message: {
            Text("This will remove \"\(sandbox.name)\". This action cannot be undone.")
        }
    }
}

struct SandboxDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.sectionTitleFont)
            content
        }
    }
}

struct WorkloadDetailView: View {
    @EnvironmentObject private var appState: AppState

    let sandbox: SandboxRecord
    let workload: WorkloadRecord
    let viewportHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workload")
                            .font(AppTheme.titleFont)
                        Text(sandbox.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    StatusBadge(text: workload.status.label, color: workload.status.color)
                }

                Text(workload.command)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    if workload.status == .running {
                        Button("Stop Workload") {
                            appState.stopWorkload(sandboxID: sandbox.id, workloadID: workload.id)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.isMutating)
                    } else {
                        Button("Remove Workload", role: .destructive) {
                            appState.removeWorkload(sandboxID: sandbox.id, workloadID: workload.id)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.isMutating)
                    }
                }
            }
            .padding(18)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if workload.isTerminal {
                InteractiveTerminalBlock(
                    sandbox: sandbox,
                    workload: workload,
                    terminalHeight: terminalHeight
                )
            }

            InfoCard(title: "Basic Info") {
                PropertyRow(label: "Workload ID", value: workload.id)
                PropertyRow(label: "Working Dir", value: workload.workingDirectory)
                PropertyRow(label: "Image-backed", value: workload.isImageBacked ? "Yes" : "No")
                PropertyRow(label: "Started", value: workload.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                PropertyRow(label: "Exited", value: workload.exitedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                PropertyRow(label: "Exit Code", value: workload.exitCode.map(String.init) ?? "—")
            }

            InfoCard(title: "Logs") {
                LiveLogBlock(title: "STDOUT", path: workload.stdoutLogPath, isFollowing: workload.status == .running)
                LiveLogBlock(title: "STDERR", path: workload.stderrLogPath, isFollowing: workload.status == .running)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var terminalHeight: CGFloat {
        guard workload.isTerminal else { return 0 }

        let availableAfterHeader = viewportHeight - 280
        return min(320, max(180, availableAfterHeader))
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
    @AppStorage("openBoxTerminalDiagnosticsEnabled") private var terminalDiagnosticsEnabled = false

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

                InfoCard(title: "Terminal Diagnostics") {
                    Toggle("Write terminal diagnostics logs", isOn: $terminalDiagnosticsEnabled)
                        .toggleStyle(.switch)
                        .help("Write PTY, terminal-response, layout, and resize diagnostics to a temporary log file.")
                    Text("When enabled, each interactive terminal writes a temporary diagnostics log. The active log path appears below the terminal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
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

    @State private var mode: WorkloadRunMode = .command
    @State private var shellCommand: String
    @State private var shellPath: String
    @State private var workingDirectory: String

    init(sandbox: SandboxRecord) {
        self.sandbox = sandbox
        _shellCommand = State(initialValue: sandbox.isMacOSGuest ? "sw_vers" : "uname -a")
        _shellPath = State(initialValue: sandbox.shellPath)
        _workingDirectory = State(initialValue: sandbox.workspacePath == nil ? "/" : sandbox.guestWorkspacePath)
    }

    private var canSubmit: Bool {
        switch mode {
        case .command:
            return !shellCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .interactiveShell:
            return sandbox.isMacOSGuest && !shellPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var primaryActionTitle: String {
        switch mode {
        case .command:
            return "Run"
        case .interactiveShell:
            return "Start Shell"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Run Command")
                .font(AppTheme.titleFont)

            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(WorkloadRunMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("Sandbox: \(sandbox.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                switch mode {
                case .command:
                    TextField("Shell command", text: $shellCommand)
                    TextField("Working directory", text: $workingDirectory)
                    Text("Commands run as `\(sandbox.shellPath) -lc <command>` inside the sandbox.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .interactiveShell:
                    TextField("Shell executable", text: $shellPath)
                    TextField("Working directory", text: $workingDirectory)
                    Text(shellModeHelpText)
                        .font(.caption)
                        .foregroundColor(sandbox.isMacOSGuest ? .secondary : AppTheme.danger)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button(primaryActionTitle) {
                    let submittedDraft = WorkloadDraft(
                        sandboxID: sandbox.id,
                        mode: mode,
                        shellCommand: shellCommand,
                        shellPath: shellPath,
                        workingDirectory: workingDirectory
                    )
                    dismiss()
                    Task { @MainActor in
                        appState.runWorkload(submittedDraft)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .accessibilityLabel(primaryActionTitle)
            }
        }
        .padding(24)
        .frame(width: 560)
    }

    private var shellModeHelpText: String {
        guard sandbox.isMacOSGuest else {
            return "Interactive shell workloads are currently supported for macOS sandboxes only."
        }
        return "Starts a TTY shell and opens it in the workload detail terminal after launch."
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

    private var usesStackedLayout: Bool {
        value.count > 36 || value.contains("/") || value.contains("@") || value.contains(":")
    }

    var body: some View {
        Group {
            if usesStackedLayout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .foregroundColor(.secondary)
                    Text(value)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .top) {
                    Text(label)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 16)
                    Text(value)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }
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

struct InteractiveTerminalBlock: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("openBoxTerminalAllowsInlineGraphics") private var allowsInlineGraphics = false
    @AppStorage("openBoxTerminalDiagnosticsEnabled") private var diagnosticsEnabled = false

    let sandbox: SandboxRecord
    let workload: WorkloadRecord
    let terminalHeight: CGFloat

    private var terminalIO: InteractiveWorkloadIO? {
        appState.interactiveTerminal(sandboxID: sandbox.id, workloadID: workload.id)
    }

    private var diagnosticsContext: TerminalDiagnosticsContext {
        TerminalDiagnosticsContext(sandboxID: sandbox.id, workloadID: workload.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Terminal")
                    .font(AppTheme.sectionTitleFont)
                if workload.status == .running {
                    Label("Live", systemImage: "record.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.accent)
                        .labelStyle(.titleAndIcon)
                }
                Spacer(minLength: 12)
                Toggle("Inline graphics", isOn: $allowsInlineGraphics)
                    .toggleStyle(.switch)
                    .font(.caption2)
                    .help("Allow terminal image protocols such as Kitty, iTerm2, and sixel.")
            }

            if workload.status == .running, let terminalIO {
                EmbeddedTerminalView(
                    terminalIO: terminalIO,
                    allowsInlineGraphics: allowsInlineGraphics,
                    diagnostics: diagnosticsEnabled ? diagnosticsContext : nil,
                    onResize: { columns, rows in
                        appState.resizeInteractiveTerminal(
                            sandboxID: sandbox.id,
                            workloadID: workload.id,
                            columns: columns,
                            rows: rows
                        )
                    },
                    onError: { error in
                        appState.showInteractiveTerminalError(error)
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: terminalHeight)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                        .allowsHitTesting(false)
                )
            } else {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .background(AppTheme.background.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
            }

            Text(footerText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var statusText: String {
        if workload.status != .running {
            return "The shell is no longer running."
        }
        return "Terminal I/O is only available for shells started in this app session."
    }

    private var footerText: String {
        let baseText: String
        if workload.status == .running, terminalIO != nil {
            if allowsInlineGraphics {
                baseText = "Click the terminal and type normally. Inline graphics are allowed."
            } else {
                baseText = "Click the terminal and type normally. Inline graphics are hidden for text stability."
            }
        } else {
            baseText = "Start a new interactive shell to use direct keyboard input."
        }

        if diagnosticsEnabled {
            return "\(baseText) Diagnostics: \(diagnosticsContext.logURL.path)"
        }
        return baseText
    }
}

struct LiveLogBlock: View {
    private static let bottomID = "log-bottom"

    let title: String
    let path: String?
    let isFollowing: Bool

    @State private var snapshot = LogFileSnapshot.missingPath

    private var taskID: String {
        "\(path ?? "")|\(isFollowing)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if isFollowing {
                    Label("Live", systemImage: "record.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.accent)
                        .labelStyle(.titleAndIcon)
                }
            }

            if let path, !path.isEmpty {
                Text(path)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    VStack(alignment: .leading, spacing: 6) {
                        if snapshot.isTruncated {
                            Text("Showing the last \(LogFileSnapshot.byteLimitLabel).")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text(snapshot.displayText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(snapshot.foregroundColor)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id(Self.bottomID)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 92, maxHeight: 180)
                .background(AppTheme.background.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )
                .onChange(of: snapshot.displayText) { _, _ in
                    guard isFollowing else { return }
                    proxy.scrollTo(Self.bottomID, anchor: .bottom)
                }
            }
        }
        .task(id: taskID) {
            await streamLog()
        }
    }

    @MainActor
    private func streamLog() async {
        guard let path, !path.isEmpty else {
            snapshot = .missingPath
            return
        }

        while !Task.isCancelled {
            let nextSnapshot = await LogFileSnapshot.load(path: path)
            guard !Task.isCancelled else { return }
            snapshot = nextSnapshot

            guard isFollowing else { return }
            try? await Task.sleep(nanoseconds: 700_000_000)
        }
    }
}

struct LogFileSnapshot: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case missingPath
        case waiting
        case empty
        case content
        case error
    }

    static let byteLimit = 64 * 1024
    static let byteLimitLabel = "64 KB"
    static let missingPath = LogFileSnapshot(kind: .missingPath, text: "No log path was returned.", isTruncated: false)

    var kind: Kind
    var text: String
    var isTruncated: Bool

    var displayText: String {
        text
    }

    var foregroundColor: Color {
        switch kind {
        case .error:
            return AppTheme.danger
        case .missingPath, .waiting, .empty:
            return .secondary
        case .content:
            return .primary
        }
    }

    static func load(path: String) async -> LogFileSnapshot {
        await Task.detached(priority: .utility) {
            read(path: path)
        }.value
    }

    private static func read(path: String) -> LogFileSnapshot {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return LogFileSnapshot(kind: .waiting, text: "Waiting for log output...", isTruncated: false)
        }
        guard !isDirectory.boolValue else {
            return LogFileSnapshot(kind: .error, text: "Log path points to a directory.", isTruncated: false)
        }

        do {
            let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
            defer { try? fileHandle.close() }

            let size = try fileHandle.seekToEnd()
            let isTruncated = size > UInt64(byteLimit)
            let offset = isTruncated ? size - UInt64(byteLimit) : 0
            try fileHandle.seek(toOffset: offset)
            let data = try fileHandle.readToEnd() ?? Data()
            let text = String(decoding: data, as: UTF8.self)

            guard !text.isEmpty else {
                return LogFileSnapshot(kind: .empty, text: "No output yet.", isTruncated: false)
            }

            return LogFileSnapshot(kind: .content, text: text, isTruncated: isTruncated)
        } catch {
            return LogFileSnapshot(kind: .error, text: error.openBoxMessage, isTruncated: false)
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

extension Date {
    var compactRelativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
