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
    @State private var showingAddImage = false
    @State private var showingCreateSandbox = false
    @State private var createSandboxReference: String?
    @State private var runWorkloadTarget: SandboxRecord?

    private var toolbarTitle: String {
        switch appState.selectedSidebar {
        case .sandboxes:
            return appState.selectedSandbox?.name ?? "Sandboxes"
        case .images:
            return appState.selectedImage?.reference ?? "Images"
        case .settings:
            return "Settings"
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $appState.selectedSidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 232, max: 250)
        } content: {
            switch appState.selectedSidebar {
            case .sandboxes:
                SandboxListView(showCreateSandbox: $showingCreateSandbox)
            case .images:
                ImageListView(
                    showAddImage: $showingAddImage,
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
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ToolbarBreadcrumb(title: toolbarTitle)
            }
        }
        .toolbar(removing: .title)
        .sheet(isPresented: $showingAddImage) {
            AddImageSheet()
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
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(AppTheme.windowChromeSurface)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let activityMessage = appState.activityMessage {
                ActivityBubble(message: activityMessage)
                    .padding(20)
            }
        }
        .font(AppTheme.bodyFont)
        .tint(AppTheme.accent)
        .background(AppTheme.windowSurface.ignoresSafeArea())
        .background(WindowChromeConfigurator())
        .preferredColorScheme(.light)
        .frame(minWidth: 1180, minHeight: 680)
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.appearance = NSAppearance(named: .aqua)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified
        window.titlebarSeparatorStyle = .line
        window.backgroundColor = NSColor(
            red: 246 / 255,
            green: 247 / 255,
            blue: 251 / 255,
            alpha: 1
        )
    }
}

struct ToolbarBreadcrumb: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text("OpenBox")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.outline)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.outline.opacity(0.75))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.onSurface)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: 220, alignment: .leading)
        .frame(height: 18, alignment: .leading)
        .controlSize(.small)
    }
}

struct OpenBoxBrandIcon: View {
    let size: CGFloat

    var body: some View {
        Image("OpenBoxIcon")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selection: SidebarSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                OpenBoxBrandIcon(size: 28)

                Text("OpenBox")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.onSurface)
            }
            .padding(.horizontal, 16)
            .padding(.top, 30)
            .padding(.bottom, 28)

            SidebarGroupTitle("Workspace")

            VStack(alignment: .leading, spacing: 4) {
                ForEach([SidebarSection.sandboxes, .images]) { section in
                    Button {
                        selection = section
                    } label: {
                        SidebarRow(
                            section: section,
                            isSelected: selection == section,
                            count: count(for: section)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            SidebarGroupTitle("System")
                .padding(.top, 26)

            Button {
                selection = .settings
            } label: {
                SidebarRow(
                    section: .settings,
                    isSelected: selection == .settings,
                    count: nil
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Circle()
                    .fill(appState.systemStatus.isAvailable ? AppTheme.success : AppTheme.outline)
                    .frame(width: 7, height: 7)
                Text("Runtime")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.onSurfaceVariant)
                Text(appState.systemStatus.isAvailable ? "online" : "offline")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.onSurface)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
            }
        }
        .background(AppTheme.sidebarSurface)
    }

    private func count(for section: SidebarSection) -> Int? {
        switch section {
        case .sandboxes:
            return appState.sandboxes.count
        case .images:
            return appState.displayedImages.count
        case .settings:
            return nil
        }
    }
}

struct SidebarGroupTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppTheme.outline.opacity(0.72))
            .textCase(.uppercase)
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
    }
}

struct SidebarRow: View {
    let section: SidebarSection
    let isSelected: Bool
    let count: Int?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? AppTheme.accent : AppTheme.outline)
                .frame(width: 20)

            Text(section.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? AppTheme.onSurface : AppTheme.onSurfaceVariant)

            Spacer(minLength: 0)

            if let count {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.outline)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppTheme.sidebarSelectedSurface : Color.clear)
        )
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
        VStack(spacing: 0) {
            ListColumnHeader(
                title: "Sandboxes",
                count: appState.sandboxes.count,
                primaryTitle: "New",
                primarySystemImage: "plus",
                secondarySystemImage: "arrow.clockwise",
                primaryDisabled: appState.isMutating,
                secondaryDisabled: appState.isRefreshing || appState.isMutating,
                primaryAction: {
                    showCreateSandbox = true
                },
                secondaryAction: {
                    Task {
                        await appState.refreshAll()
                    }
                }
            )

            SearchField(title: "Search sandboxes", text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            if !appState.systemStatus.isAvailable {
                ServiceUnavailableView(message: appState.systemStatus.lastError)
                    .padding(.horizontal, 16)
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
                                        .padding(.leading, 30)
                                        .padding(.vertical, 6)
                                } else {
                                    Text("Workloads")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppTheme.outline)
                                        .textCase(.uppercase)
                                        .padding(.leading, 72)
                                        .padding(.top, 8)

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
                                        .padding(.leading, 56)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 292, ideal: 328, max: 360)
        .background(AppTheme.contentSurface)
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
            HStack(alignment: .center, spacing: 12) {
                selectionMark

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.outline)
                    .frame(width: 12)

                SandboxGlyph(color: sandbox.status.color, fill: sandbox.status.fillColor)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(sandbox.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.onSurface)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .layoutPriority(1)

                        Spacer(minLength: 10)

                        StatusPill(text: sandbox.status.label, color: sandbox.status.color, fill: sandbox.status.fillColor)
                    }

                    Text(sandbox.id)
                        .font(AppTheme.monoSmallFont)
                        .foregroundColor(AppTheme.outline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 8) {
                        Text(resourceLine)
                            .font(AppTheme.metadataFont)
                            .foregroundColor(AppTheme.outline)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        if let startedAt = sandbox.startedAt, sandbox.status.isRunning {
                            Text(startedAt.compactRelativeDescription)
                                .font(AppTheme.metadataFont)
                                .foregroundColor(AppTheme.outline)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 0)
        .padding(.vertical, isSelected ? 12 : 10)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppTheme.selectionSurface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isSelected ? AppTheme.selectionStroke : Color.clear,
                    lineWidth: isSelected ? 1 : 0
                )
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.025 : 0), radius: 8, y: 2)
    }

    private var resourceLine: String {
        let workloadLabel = workloadCount == 1 ? "1 active" : "\(workloadCount) active"
        return "\(workloadLabel) · \(sandbox.cpuCores) vCPU · \(sandbox.memoryGB) GB"
    }

    @ViewBuilder
    private var selectionMark: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.selectionMark)
                .frame(width: 4, height: 74)
        } else {
            Color.clear.frame(width: 4, height: 74)
        }
    }
}

struct SandboxGlyph: View {
    let color: Color
    let fill: Color
    var size: CGFloat = 30
    var symbolSize: CGFloat = 13
    var cornerRadius: CGFloat = 8

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
            Image(systemName: "cube.box.fill")
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

struct SandboxTreeWorkloadRow: View {
    let workload: WorkloadRecord
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                selectionMark

                Circle()
                    .fill(workload.status.color)
                    .frame(width: 6, height: 6)

                Text(workload.command)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .monospaced))
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(workload.startedAt?.compactRelativeDescription ?? workload.status.label)
                    .font(AppTheme.metadataFont)
                    .foregroundColor(workload.status == .running ? AppTheme.accent : AppTheme.outline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppTheme.selectionSurface : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(isSelected ? 0.025 : 0), radius: 6, y: 2)
    }

    @ViewBuilder
    private var selectionMark: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.selectionMark)
                .frame(width: 3, height: 28)
        } else {
            Color.clear.frame(width: 3, height: 28)
        }
    }
}

struct ImageListView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showAddImage: Bool

    let onCreateSandbox: (String) -> Void

    @State private var searchText = ""

    private var filteredImages: [OCIImageRecord] {
        guard !searchText.isEmpty else { return appState.displayedImages }
        return appState.displayedImages.filter { image in
            image.reference.localizedCaseInsensitiveContains(searchText) ||
            image.digest.localizedCaseInsensitiveContains(searchText) ||
            image.matchesBuiltInSearch(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ListColumnHeader(
                title: "Images",
                count: appState.displayedImages.count,
                primaryTitle: "Add",
                primarySystemImage: "plus",
                secondarySystemImage: "arrow.clockwise",
                primaryDisabled: appState.isMutating,
                secondaryDisabled: appState.isRefreshing || appState.isMutating,
                primaryAction: {
                    showAddImage = true
                },
                secondaryAction: {
                    Task {
                        await appState.refreshAll()
                    }
                }
            )

            SearchField(title: "Search images", text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            if !appState.systemStatus.isAvailable {
                ServiceUnavailableView(message: appState.systemStatus.lastError)
                    .padding(.horizontal, 16)
                Spacer()
            } else if filteredImages.isEmpty {
                EmptyStateView(
                    title: "No images",
                    message: "Add an OCI image reference to track it, or pull it so new sandboxes can use it."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredImages) { image in
                            let isSelected = appState.isSelectedImage(image)
                            Button {
                                appState.selectedImageReference = image.reference
                            } label: {
                                ImageRow(
                                    image: image,
                                    progress: appState.imagePullProgress(for: image.reference),
                                    isSelected: isSelected
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if image.isDownloaded {
                                    Button("Create Sandbox") {
                                        onCreateSandbox(image.reference)
                                    }
                                } else if image.isPulling {
                                    Button("Pulling Image") {}
                                        .disabled(true)
                                } else {
                                    Button("Pull Image") {
                                        appState.pullImage(reference: image.reference)
                                    }
                                }
                                if image.canDeleteOrRemove {
                                    Button(image.destructiveActionTitle, role: .destructive) {
                                        appState.deleteImage(reference: image.reference)
                                    }
                                    .disabled(image.isPulling)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 360, ideal: 408, max: 430)
        .background(AppTheme.contentSurface)
    }
}

struct SettingsSummaryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            ListColumnHeader(
                title: "System",
                secondarySystemImage: "arrow.clockwise",
                secondaryDisabled: appState.isRefreshing || appState.isMutating,
                secondaryAction: {
                    Task {
                        await appState.refreshAll()
                    }
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    SettingsCard(
                        title: "Container Services",
                        detail: appState.systemStatus.isAvailable
                            ? "Connected to local node"
                            : (appState.systemStatus.lastError ?? "Container services unavailable"),
                        isSelected: true
                    )
                    SettingsCard(
                        title: "Diagnostics",
                        detail: "Terminal logging"
                    )
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 16)
            }
        }
        .navigationSplitViewColumnWidth(min: 360, ideal: 408, max: 430)
        .background(AppTheme.contentSurface)
    }
}

struct DetailColumnView: View {
    @EnvironmentObject private var appState: AppState

    @Binding var showCreateSandbox: Bool
    @Binding var createSandboxReference: String?
    let onRunCommand: (SandboxRecord) -> Void

    var body: some View {
        Group {
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
                        progress: appState.imagePullProgress(for: image.reference),
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.detailSurface)
    }
}

struct ImageRow: View {
    let image: OCIImageRecord
    let progress: ImagePullProgress?
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            selectionMark

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(image.reference)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(AppTheme.onSurface)
                        .lineLimit(2)
                        .truncationMode(.middle)

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                    }
                }

                HStack(spacing: 8) {
                    StatusPill(
                        text: image.availability.label,
                        color: image.availability.color,
                        fill: image.availability.fillColor
                    )
                    if image.isBuiltIn {
                        StatusPill(text: image.builtInLabel, color: AppTheme.secondary, fill: AppTheme.detailSurface)
                    }
                    if image.isDownloaded {
                        StatusPill(text: image.shortDigest, color: AppTheme.secondary, fill: AppTheme.detailSurface)
                    }
                    Text(image.platformLabel.ifEmpty(image.mediaType))
                        .font(AppTheme.metadataFont)
                        .foregroundColor(AppTheme.outline)
                        .italic()
                        .lineLimit(1)
                }

                if image.isPulling {
                    ImagePullProgressLine(progress: progress)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppTheme.selectionSurface : Color.clear)
        )
    }

    @ViewBuilder
    private var selectionMark: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.selectionMark)
                .frame(width: 3, height: 34)
                .padding(.top, 1)
        } else {
            Color.clear.frame(width: 3, height: 34)
        }
    }
}

struct ImagePullProgressLine: View {
    let progress: ImagePullProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Group {
                if let fractionCompleted = progress?.fractionCompleted {
                    ProgressView(value: fractionCompleted)
                } else {
                    ProgressView()
                }
            }
            .progressViewStyle(.linear)
            .tint(AppTheme.accent)

            Text(progress?.summary ?? "Waiting for registry")
                .font(AppTheme.metadataFont)
                .foregroundColor(AppTheme.outline)
                .lineLimit(1)
        }
        .accessibilityLabel(progress?.summary ?? "Pulling image")
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
            if let selectedWorkload {
                VStack(spacing: 0) {
                    WorkloadStatusBar(sandbox: sandbox, workload: selectedWorkload)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if !appState.systemStatus.isAvailable {
                                ServiceUnavailableView(message: appState.systemStatus.lastError)
                            }

                            WorkloadDetailView(
                                sandbox: sandbox,
                                workload: selectedWorkload,
                                viewportHeight: proxy.size.height
                            )
                        }
                        .padding(24)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !appState.systemStatus.isAvailable {
                            ServiceUnavailableView(message: appState.systemStatus.lastError)
                        }

                        SandboxSummaryCard(
                            sandbox: sandbox,
                            detail: detail,
                            onRunCommand: {
                                onRunCommand(sandbox)
                            }
                        )
                    }
                    .padding(24)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.detailSurface)
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

    private var uptimeText: String {
        guard sandbox.status.isRunning, let startedAt = sandbox.startedAt else {
            return "Uptime -"
        }

        let interval = max(0, Int(Date().timeIntervalSince(startedAt)))
        let days = interval / 86_400
        let hours = (interval % 86_400) / 3_600
        let minutes = (interval % 3_600) / 60

        if days > 0 {
            return "Uptime \(days)d \(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "Uptime \(hours)h \(minutes)m"
        }
        return "Uptime \(minutes)m"
    }

    private var desktopActionDisabled: Bool {
        appState.isMutating ||
        !sandbox.isMacOSGuest ||
        !sandbox.desktopGUIEnabled ||
        sandbox.status == .creating ||
        sandbox.status == .pulling ||
        sandbox.status == .starting ||
        sandbox.status == .stopping
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            summaryHeader

            actionStrip

            SandboxDesktopPanel(
                sandbox: sandbox,
                isActionDisabled: desktopActionDisabled,
                onLaunchDesktop: {
                    appState.launchDesktop(for: sandbox.id)
                }
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    configurationSection
                    networkSection
                }

                VStack(alignment: .leading, spacing: 16) {
                    configurationSection
                    networkSection
                }
            }

            if let lastError = sandbox.lastError ?? detail?.lastError {
                SandboxDetailSection(title: "Last Error") {
                    Text(lastError)
                        .font(AppTheme.monoFont)
                        .foregroundColor(AppTheme.danger)
                        .textSelection(.enabled)
                }
            }

            DiagnosticLogPathDisclosure(logPaths: detail?.logPaths)

            SectionBreak()

            HStack {
                Spacer()
                Button(role: .destructive) {
                    showingRemoveConfirmation = true
                } label: {
                    Label("Remove Sandbox", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(AppTheme.danger)
                .disabled(appState.isMutating)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppTheme.detailSurface)
        .alert("Remove Sandbox?", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove Sandbox", role: .destructive) {
                appState.removeSandbox(sandbox.id)
            }
        } message: {
            Text("This will remove \"\(sandbox.name)\". This action cannot be undone.")
        }
    }

    private var summaryHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            OpenBoxBrandIcon(size: 62)

            VStack(alignment: .leading, spacing: 10) {
                Text(sandbox.name)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    StatusBadge(text: sandbox.status.label, color: sandbox.status.color, fill: sandbox.status.fillColor)
                    Text(uptimeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }

                Text(sandbox.id)
                    .font(AppTheme.monoSmallFont)
                    .foregroundColor(AppTheme.outline)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.onSurfaceVariant)
            .allowsHitTesting(false)
        }
    }

    private var actionStrip: some View {
        HStack(spacing: 12) {
            Button {
                onRunCommand()
            } label: {
                Label("Run Command", systemImage: "terminal")
                    .frame(minWidth: 132)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(AppTheme.accent)
            .disabled(!sandbox.status.isRunning || appState.isMutating)
            .help("Run Command")

            Button {
                appState.toggleSandbox(sandbox.id)
            } label: {
                Label(toggleSandboxTitle, systemImage: toggleSandboxIcon)
                    .frame(minWidth: 132)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(sandbox.status.isRunning ? AppTheme.danger : AppTheme.accent)
            .foregroundColor(sandbox.status.isRunning ? AppTheme.danger : AppTheme.accent)
            .disabled(appState.isMutating || sandbox.status == .creating || sandbox.status == .pulling)
            .help(toggleSandboxTitle)

            if sandbox.isMacOSGuest && sandbox.desktopGUIEnabled {
                Button {
                    appState.launchDesktop(for: sandbox.id)
                } label: {
                    Label("Launch Desktop", systemImage: "display")
                        .frame(minWidth: 132)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(desktopActionDisabled)
                .help("Launch Desktop")
            }

            Spacer(minLength: 12)

            Button {
                Task {
                    await appState.refreshSandbox(id: sandbox.id)
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.onSurfaceVariant)
            .disabled(appState.isRefreshing || appState.isMutating)
        }
    }

    private var configurationSection: some View {
        SandboxDetailSection(title: "Configuration") {
            PropertyRow(label: "OCI Image", value: sandbox.imageReference)
            PropertyRow(label: "Digest", value: sandbox.imageDigest.shortDigest)
            PropertyRow(label: "Runtime", value: sandbox.runtimeHandler)
            PropertyRow(label: "Platform", value: sandbox.platform)
            PropertyRow(label: "Desktop GUI", value: desktopGUIValue)
            PropertyRow(label: "Resources", value: "\(sandbox.cpuCores) vCPU / \(sandbox.memoryGB)GB RAM")
            PropertyRow(label: "Workspace", value: sandbox.workspacePath ?? "Not mounted")
            PropertyRow(label: "Share Mode", value: sandbox.shareMode?.label ?? "-")
        }
        .frame(minWidth: 260, maxWidth: .infinity)
    }

    private var desktopGUIValue: String {
        guard sandbox.isMacOSGuest else { return "Unsupported" }
        return sandbox.desktopGUIEnabled ? "Enabled" : "Disabled"
    }

    private var networkSection: some View {
        SandboxDetailSection(title: "Network Identity") {
            if let network = detail?.networks.first {
                PropertyRow(label: "Hostname", value: network.hostname)
                PropertyRow(label: "IPv4 Address", value: network.ipv4Address)
                PropertyRow(label: "Gateway", value: network.gateway)
                PropertyRow(label: "DNS Resolver", value: network.dnsServers.joined(separator: ", ").ifEmpty("-"))
            } else {
                Text("No network attachments reported.")
                    .font(AppTheme.metadataFont)
                    .foregroundColor(AppTheme.outline)
            }
        }
        .frame(minWidth: 260, maxWidth: .infinity)
    }
}

struct SandboxDesktopPanel: View {
    let sandbox: SandboxRecord
    let isActionDisabled: Bool
    let onLaunchDesktop: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                Text("Sandbox Desktop")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundColor(AppTheme.onSurface)
                StatusBadge(text: desktopStatusText, color: desktopStatusColor, fill: desktopStatusFill)
                Spacer(minLength: 12)
                if showsLaunchDesktopButton {
                    Button {
                        onLaunchDesktop()
                    } label: {
                        Label("Launch Desktop", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isActionDisabled)
                    .help("Launch Desktop")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.surfaceSubtle)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    desktopGlyph

                    VStack(alignment: .leading, spacing: 6) {
                        Text(desktopTitle)
                            .font(AppTheme.titleSmallFont)
                            .foregroundColor(AppTheme.onSurface)
                        Text(desktopMessage)
                            .font(AppTheme.metadataFont)
                            .foregroundColor(AppTheme.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    PathCapsule(brandIconText: sandbox.id)
                    if sandbox.isMacOSGuest {
                        PathCapsule(
                            systemImage: "display",
                            text: sandbox.desktopGUIEnabled ? "desktop window enabled" : "desktop disabled"
                        )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.detailSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    private var desktopGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.selectionSurface)
                .frame(width: 52, height: 52)
            Image(systemName: desktopGlyphName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(desktopStatusColor)
        }
    }

    private var desktopGlyphName: String {
        if !sandbox.isMacOSGuest || !sandbox.desktopGUIEnabled {
            return "desktopcomputer.trianglebadge.exclamationmark"
        }
        if sandbox.status.isRunning {
            return "desktopcomputer"
        }
        return "play.display"
    }

    private var showsLaunchDesktopButton: Bool {
        sandbox.isMacOSGuest && sandbox.desktopGUIEnabled
    }

    private var desktopTitle: String {
        guard sandbox.isMacOSGuest else {
            return "Desktop GUI is not available for this sandbox"
        }
        guard sandbox.desktopGUIEnabled else {
            return "Desktop GUI was not enabled at creation time"
        }
        if sandbox.status.isRunning {
            return "Desktop window can be opened on demand"
        }
        return "Launch opens the native VM desktop window"
    }

    private var desktopMessage: String {
        guard sandbox.isMacOSGuest else {
            return "The MVP supports native desktop windows for macOS guest sandboxes. Linux desktop sessions need a separate remote desktop backend."
        }
        guard sandbox.desktopGUIEnabled else {
            return "Create a new macOS guest sandbox with Enable desktop GUI turned on to use the runtime-managed desktop window."
        }
        if sandbox.status.isRunning {
            return "Open or reopen the native Virtualization desktop window without changing the sandbox state. Closing the window leaves the sandbox running."
        }
        return "Starting the sandbox normally keeps the desktop hidden. Launch Desktop starts or opens the native window only when you ask for it."
    }

    private var desktopStatusText: String {
        guard sandbox.isMacOSGuest else { return "Unsupported" }
        guard sandbox.desktopGUIEnabled else { return "Disabled" }
        return sandbox.status.isRunning ? "Ready" : "Available"
    }

    private var desktopStatusColor: Color {
        guard sandbox.isMacOSGuest, sandbox.desktopGUIEnabled else {
            return AppTheme.outline
        }
        return AppTheme.success
    }

    private var desktopStatusFill: Color {
        guard sandbox.isMacOSGuest, sandbox.desktopGUIEnabled else {
            return AppTheme.stoppedSurface
        }
        return AppTheme.successSurface
    }
}

struct SandboxDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.outline)
                    .textCase(.uppercase)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.fieldSurface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

struct DiagnosticLogPathDisclosure: View {
    let logPaths: SandboxLogRecord?

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                if let logPaths {
                    CopyablePathRow(label: "Event", path: logPaths.eventLogPath)
                    CopyablePathRow(label: "Boot", path: logPaths.bootLogPath)
                    CopyablePathRow(label: "Guest Agent STDOUT", path: logPaths.guestAgentLogPath)
                    CopyablePathRow(label: "Guest Agent STDERR", path: logPaths.guestAgentStderrLogPath)
                } else {
                    Text("No sandbox log paths were returned.")
                        .font(AppTheme.metadataFont)
                        .foregroundColor(AppTheme.outline)
                }
            }
            .padding(.top, 10)
        } label: {
            Text("Diagnostic Log Paths")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.outline)
                .textCase(.uppercase)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

struct WorkloadStatusBar: View {
    @EnvironmentObject private var appState: AppState

    let sandbox: SandboxRecord
    let workload: WorkloadRecord

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(workload.command)
                    .font(AppTheme.titleSmallFont)
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                HStack(spacing: 10) {
                    Text(sandbox.name)
                        .font(AppTheme.monoSmallFont)
                        .foregroundColor(AppTheme.outline)
                        .lineLimit(1)
                    Text(workload.id)
                        .font(AppTheme.monoSmallFont)
                        .foregroundColor(AppTheme.outline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            StatusBadge(text: workload.status.label, color: workload.status.color)

            if workload.status == .running {
                Button(role: .destructive) {
                    appState.stopWorkload(sandboxID: sandbox.id, workloadID: workload.id)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(AppTheme.danger)
                .disabled(appState.isMutating)
            } else {
                Button(role: .destructive) {
                    appState.removeWorkload(sandboxID: sandbox.id, workloadID: workload.id)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(appState.isMutating)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(AppTheme.detailSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.surfaceContainerHigh)
                .frame(height: 1)
        }
    }
}

struct WorkloadDetailView: View {
    let sandbox: SandboxRecord
    let workload: WorkloadRecord
    let viewportHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if workload.isTerminal {
                InteractiveTerminalBlock(
                    sandbox: sandbox,
                    workload: workload,
                    terminalHeight: terminalHeight
                )
            } else {
                WorkloadTerminalOutputBlock(workload: workload)
            }

            InfoCard(title: "Basic Info") {
                PropertyRow(label: "Workload ID", value: workload.id)
                PropertyRow(label: "Working Dir", value: workload.workingDirectory)
                PropertyRow(label: "Image-backed", value: workload.isImageBacked ? "Yes" : "No")
                PropertyRow(label: "Started", value: workload.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                PropertyRow(label: "Exited", value: workload.exitedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                PropertyRow(label: "Exit Code", value: workload.exitCode.map(String.init) ?? "—")
                CopyablePathRow(label: "STDOUT Log", path: workload.stdoutLogPath)
                CopyablePathRow(label: "STDERR Log", path: workload.stderrLogPath)
            }
        }
        .frame(maxWidth: 980, alignment: .topLeading)
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
    let progress: ImagePullProgress?
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
                        StatusBadge(
                            text: image.availability.label,
                            color: image.availability.color,
                            fill: image.availability.fillColor
                        )
                        if image.isDownloaded {
                            StatusBadge(text: image.shortDigest, color: AppTheme.accent)
                        }
                        if image.isBuiltIn {
                            StatusBadge(text: image.builtInLabel, color: AppTheme.secondary, fill: AppTheme.selectionSurface)
                        }
                        Text(image.mediaType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        if image.isDownloaded {
                            Button("Create Sandbox") {
                                onCreateSandbox()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(appState.isMutating)
                        } else if image.isPulling {
                            Button("Pulling Image") {}
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        } else {
                            Button("Pull Image") {
                                appState.pullImage(reference: image.reference)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(appState.isMutating)
                        }

                        if image.canDeleteOrRemove {
                            Button(image.destructiveActionTitle, role: .destructive) {
                                appState.deleteImage(reference: image.reference)
                            }
                            .buttonStyle(.bordered)
                            .disabled(appState.isMutating || image.isPulling)
                        }
                    }

                    if image.isPulling {
                        ImagePullProgressLine(progress: progress)
                    }
                }
                .padding(18)
                .background(AppTheme.contentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                InfoCard(title: "Reference") {
                    PropertyRow(label: "OCI Reference", value: image.reference)
                    PropertyRow(label: "Digest", value: image.digest.ifEmpty("—"))
                    PropertyRow(label: "Media Type", value: image.mediaType)
                    PropertyRow(label: "Platforms", value: image.platformLabel.ifEmpty("—"))
                }

                InfoCard(title: "Usage") {
                    Text(image.usageDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(28)
        }
        .background(AppTheme.detailSurface)
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
                    if let lastError = appState.systemStatus.lastError {
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
                            .textSelection(.enabled)
                    }
                }

                InfoCard(title: "File Locations") {
                    PathBlock(title: "App Root", path: appState.systemStatus.appRoot)
                    PathBlock(title: "Install Root", path: appState.systemStatus.installRoot)
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
            }
            .padding(28)
        }
        .background(AppTheme.detailSurface)
    }
}

struct AddImageSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ImagePullDraft()

    var body: some View {
        VStack(spacing: 0) {
            ModalHeader(
                title: "Add OCI Image",
                subtitle: "Track a reference or download it locally.",
                systemImage: "plus.circle"
            )

            VStack(alignment: .leading, spacing: 14) {
                FormLabel("Image Reference")
                TextField("ghcr.io/org/image:tag", text: $draft.reference)
                    .textFieldStyle(.plain)
                    .font(AppTheme.monoFont)
                    .padding(10)
                    .background(AppTheme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .innerFieldShadow()

                InfoNote(
                    title: "Image Flow",
                    message: "Add stores the reference locally. Pull downloads public images anonymously unless registry sign-in is enabled."
                )

                Toggle("Use registry sign-in", isOn: $draft.usesRegistryCredentials)
                    .toggleStyle(.switch)

                if draft.usesRegistryCredentials {
                    VStack(alignment: .leading, spacing: 10) {
                        FormLabel("Registry")
                        Text(draft.registryHost ?? "Enter a reference with a registry host")
                            .font(AppTheme.monoSmallFont)
                            .foregroundColor(draft.registryHost == nil ? AppTheme.warning : AppTheme.secondary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.fieldSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .innerFieldShadow()

                        FormLabel("Username")
                        TextField("Registry username", text: $draft.registryUsername)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(AppTheme.fieldSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .innerFieldShadow()

                        FormLabel("Access Token")
                        SecureField("Registry access token", text: $draft.registryToken)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(AppTheme.fieldSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .innerFieldShadow()

                        InfoNote(
                            title: "Private Images",
                            message: "Use sign-in only for private registries or packages. OpenBox uses these details for this pull and does not use existing container registry logins."
                        )
                    }
                }
            }
            .padding(24)

            ModalFooter {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Pull") {
                    let reference = draft.reference
                    let credentials = draft.registryCredentials
                    dismiss()
                    Task { @MainActor in
                        appState.pullImage(reference: reference, credentials: credentials)
                    }
                }
                .disabled(!draft.canPull)
                Button("Add") {
                    let reference = draft.reference
                    dismiss()
                    Task { @MainActor in
                        appState.addImageReference(reference: reference)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(draft.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .frame(width: 520)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            desktopGUIEnabled: false,
            autoStart: true
        ))
    }

    private var canSubmit: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        downloadedImageReferences.contains(draft.imageReference)
    }

    private var downloadedImages: [OCIImageRecord] {
        appState.downloadedImages
    }

    private var downloadedImageReferences: [String] {
        downloadedImages.map(\.reference)
    }

    var body: some View {
        VStack(spacing: 0) {
            ModalHeader(
                title: "New Sandbox",
                subtitle: "Initialize a fresh isolated container environment.",
                systemImage: "plus.square.on.square"
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        FormLabel("Sandbox Name")
                        TextField("Sandbox name", text: $draft.name)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(AppTheme.fieldSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .innerFieldShadow()

                        FormLabel("Image Reference")
                        if downloadedImages.isEmpty {
                            Text("No downloaded images are available. Pull an image before creating a sandbox.")
                                .font(AppTheme.metadataFont)
                                .foregroundColor(AppTheme.danger)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Picker("Image Reference", selection: $draft.imageReference) {
                                ForEach(downloadedImages) { image in
                                    Text(image.reference)
                                        .tag(image.reference)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resources")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.onSurfaceVariant)
                            .textCase(.uppercase)
                        Stepper("CPU Cores: \(draft.cpuCores)", value: $draft.cpuCores, in: 2...12)
                        Stepper("Memory: \(draft.memoryGB) GB", value: $draft.memoryGB, in: 4...64, step: 2)
                        Stepper("Disk: \(draft.diskGB) GB", value: $draft.diskGB, in: 20...256, step: 10)
                    }
                    .padding(16)
                    .background(AppTheme.contentSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        FormLabel("Host Workspace")
                        HStack(spacing: 8) {
                            TextField("Host workspace (optional)", text: $draft.workspacePath)
                                .textFieldStyle(.plain)
                                .font(AppTheme.monoFont)
                                .padding(10)
                                .background(AppTheme.fieldSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .innerFieldShadow()
                            Button("Choose Folder") {
                                showFolderPicker = true
                            }
                            .controlSize(.small)
                        }

                        FormLabel("Share Mode")
                        Picker("Share Mode", selection: $draft.shareMode) {
                            ForEach(FileShareMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text("Only downloaded local images can be used to create a sandbox.")
                            .font(AppTheme.metadataFont)
                            .foregroundColor(AppTheme.outline)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Desktop")
                            .font(AppTheme.sectionTitleFont)
                            .foregroundColor(AppTheme.onSurfaceVariant)
                            .textCase(.uppercase)

                        Toggle("Enable desktop GUI for macOS guests", isOn: $draft.desktopGUIEnabled)
                            .toggleStyle(.switch)

                        Text("When the selected image resolves to a macOS guest, the runtime will attach keyboard, pointer, and graphics devices so the desktop can be opened later from the sandbox detail view.")
                            .font(AppTheme.metadataFont)
                            .foregroundColor(AppTheme.outline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(AppTheme.contentSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Toggle("Create and start immediately", isOn: $draft.autoStart)
                        .toggleStyle(.switch)
                }
                .padding(24)
            }

            ModalFooter {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
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
        .frame(width: 620)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onAppear(perform: reconcileSelectedImage)
        .onChange(of: downloadedImageReferences) { _, _ in
            reconcileSelectedImage()
        }
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                draft.workspacePath = url.path
            }
        }
    }

    private func reconcileSelectedImage() {
        guard !downloadedImageReferences.contains(draft.imageReference) else { return }
        draft.imageReference = downloadedImageReferences.first ?? ""
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
        VStack(spacing: 0) {
            ModalHeader(
                title: "Run Command",
                subtitle: sandbox.name,
                systemImage: "terminal"
            )

            VStack(alignment: .leading, spacing: 14) {
                FormLabel("Mode")
                Picker("Mode", selection: $mode) {
                    ForEach(WorkloadRunMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                PathCapsule(systemImage: "cube.box", text: sandbox.id)

                switch mode {
                case .command:
                    FormLabel("Command String")
                    TextField("Shell command", text: $shellCommand)
                        .textFieldStyle(.plain)
                        .font(AppTheme.monoFont)
                        .padding(10)
                        .background(AppTheme.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .innerFieldShadow()
                    FormLabel("Working Directory")
                    TextField("Working directory", text: $workingDirectory)
                        .textFieldStyle(.plain)
                        .font(AppTheme.monoFont)
                        .padding(10)
                        .background(AppTheme.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .innerFieldShadow()
                    Text("Commands run as `\(sandbox.shellPath) -lc <command>` inside the sandbox.")
                        .font(AppTheme.metadataFont)
                        .foregroundColor(AppTheme.outline)
                case .interactiveShell:
                    FormLabel("Shell Executable")
                    TextField("Shell executable", text: $shellPath)
                        .textFieldStyle(.plain)
                        .font(AppTheme.monoFont)
                        .padding(10)
                        .background(AppTheme.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .innerFieldShadow()
                    FormLabel("Working Directory")
                    TextField("Working directory", text: $workingDirectory)
                        .textFieldStyle(.plain)
                        .font(AppTheme.monoFont)
                        .padding(10)
                        .background(AppTheme.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .innerFieldShadow()
                    Text(shellModeHelpText)
                        .font(AppTheme.metadataFont)
                        .foregroundColor(sandbox.isMacOSGuest ? AppTheme.outline : AppTheme.danger)
                }
            }
            .padding(24)

            ModalFooter {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
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
        .frame(width: 560)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var shellModeHelpText: String {
        guard sandbox.isMacOSGuest else {
            return "Interactive shell workloads are currently supported for macOS sandboxes only."
        }
        return "Starts a TTY shell and opens it in the workload detail terminal after launch."
    }
}

struct ListColumnHeader: View {
    let title: String
    var count: Int? = nil
    var primaryTitle: String? = nil
    var primarySystemImage: String? = nil
    var secondarySystemImage: String? = nil
    var primaryDisabled = false
    var secondaryDisabled = false
    var primaryAction: (() -> Void)? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.onSurface)

            if let count {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.outline)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(AppTheme.surfaceContainer)
                    .clipShape(Capsule())
            }

            Spacer()

            if let primaryTitle, let primarySystemImage, let primaryAction {
                Button(action: primaryAction) {
                    Label(primaryTitle, systemImage: primarySystemImage)
                        .font(.system(size: 12, weight: .bold))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(AppTheme.accent)
                .disabled(primaryDisabled)
            }

            if let secondarySystemImage, let secondaryAction {
                Button(action: secondaryAction) {
                    Image(systemName: secondarySystemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.outline)
                .disabled(secondaryDisabled)
                .help("Refresh")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }
}

struct ModalHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.selectionSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.titleSmallFont)
                    .foregroundColor(AppTheme.onSurface)
                Text(subtitle)
                    .font(AppTheme.metadataFont)
                    .foregroundColor(AppTheme.outline)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(AppTheme.detailSurface)
    }
}

struct ModalFooter<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(AppTheme.contentSurface)
    }
}

struct FormLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppTheme.labelFont)
            .foregroundColor(AppTheme.onSurfaceVariant)
            .textCase(.uppercase)
    }
}

struct InfoNote: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppTheme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.secondary)
                Text(message)
                    .font(AppTheme.metadataFont)
                    .foregroundColor(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(AppTheme.selectionSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PathCapsule: View {
    let systemImage: String?
    let text: String
    let usesBrandIcon: Bool

    init(systemImage: String, text: String) {
        self.systemImage = systemImage
        self.text = text
        self.usesBrandIcon = false
    }

    init(brandIconText text: String) {
        self.systemImage = nil
        self.text = text
        self.usesBrandIcon = true
    }

    var body: some View {
        HStack(spacing: 8) {
            if usesBrandIcon {
                OpenBoxBrandIcon(size: 14)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .foregroundColor(AppTheme.outline)
            }
            Text(text)
                .font(AppTheme.monoSmallFont)
                .foregroundColor(AppTheme.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SectionBreak: View {
    var height: CGFloat = 8

    var body: some View {
        Color.clear.frame(height: height)
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
                .font(AppTheme.metadataFont)
                .foregroundColor(AppTheme.onSurfaceVariant)
                .textSelection(.enabled)
            Text("Make sure the container runtime is already installed and started before using this app.")
                .font(AppTheme.metadataFont)
                .foregroundColor(AppTheme.outline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.errorSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        VStack(spacing: 10) {
            Text(title)
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.onSurface)
            Text(message)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.outline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(AppTheme.detailSurface)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.outline)
                    .textCase(.uppercase)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.fieldSurface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

struct SettingsCard: View {
    let title: String
    let detail: String
    var isSelected = false

    var body: some View {
        HStack(spacing: 10) {
            if isSelected {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppTheme.selectionMark)
                    .frame(width: 3, height: 32)
            } else {
                Color.clear.frame(width: 3, height: 32)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(AppTheme.onSurface)
                Text(detail)
                    .font(AppTheme.metadataFont)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.outline)
                    .lineLimit(2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? AppTheme.detailSurface : Color.clear)
        )
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
                        .font(AppTheme.labelFont)
                        .foregroundColor(AppTheme.outline)
                    Text(value)
                        .font(AppTheme.monoSmallFont)
                        .foregroundColor(AppTheme.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(label)
                        .font(AppTheme.labelFont)
                        .foregroundColor(AppTheme.outline)
                    Spacer(minLength: 16)
                    Text(value)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.onSurface)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct PathBlock: View {
    let title: String
    let path: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.labelFont)
                .foregroundColor(AppTheme.outline)
                .textCase(.uppercase)
            PathCapsule(systemImage: "folder", text: path?.ifEmpty("-") ?? "-")
        }
    }
}

struct CopyablePathRow: View {
    let label: String
    let path: String?

    private var displayPath: String {
        path?.ifEmpty("—") ?? "—"
    }

    private var canCopy: Bool {
        path?.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppTheme.labelFont)
                .foregroundColor(AppTheme.outline)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                Text(displayPath)
                    .font(AppTheme.monoSmallFont)
                    .foregroundColor(canCopy ? AppTheme.secondary : AppTheme.outline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Spacer(minLength: 8)

                Button {
                    guard let path, !path.isEmpty else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(canCopy ? AppTheme.accent : AppTheme.outline)
                .disabled(!canCopy)
                .help("Copy path")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .innerFieldShadow()
        }
    }
}

struct WorkloadTerminalOutputBlock: View {
    let workload: WorkloadRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Terminal Output")
                    .font(AppTheme.sectionTitleFont)
                if workload.status == .running {
                    Label("Live", systemImage: "record.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.accent)
                        .labelStyle(.titleAndIcon)
                }
            }

            VStack(spacing: 0) {
                TerminalChromeBar(title: workload.command)
                TerminalLogContentView(
                    stdoutPath: workload.stdoutLogPath,
                    stderrPath: workload.stderrLogPath,
                    isFollowing: workload.status == .running,
                    emptyText: "No command output has been captured yet."
                )
                .frame(minHeight: 160, maxHeight: 320)
                .background(AppTheme.terminalSurface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct TerminalChromeBar: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color(red: 255 / 255, green: 95 / 255, blue: 87 / 255)).frame(width: 8, height: 8)
            Circle().fill(Color(red: 255 / 255, green: 189 / 255, blue: 46 / 255)).frame(width: 8, height: 8)
            Circle().fill(Color(red: 39 / 255, green: 201 / 255, blue: 63 / 255)).frame(width: 8, height: 8)
            Text(title)
                .font(AppTheme.monoSmallFont)
                .foregroundColor(AppTheme.terminalMuted)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.leading, 8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.terminalChrome)
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

            terminalShell

            Text(footerText)
                .font(.caption2)
                .foregroundColor(AppTheme.outline)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var terminalShell: some View {
        VStack(spacing: 0) {
            TerminalChromeBar(title: workload.command)

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
                .background(AppTheme.terminalSurface)
            } else {
                TerminalLogContentView(
                    stdoutPath: workload.stdoutLogPath,
                    stderrPath: workload.stderrLogPath,
                    isFollowing: workload.status == .running,
                    emptyText: statusText
                )
                .frame(minHeight: 128, maxHeight: 260)
                .background(AppTheme.terminalSurface)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

struct TerminalLogContentView: View {
    private static let bottomID = "terminal-log-bottom"

    let stdoutPath: String?
    let stderrPath: String?
    let isFollowing: Bool
    let emptyText: String

    @State private var output = TerminalLogOutput(text: "Waiting for log output...", isTruncated: false, isError: false)

    private var taskID: String {
        "\(stdoutPath ?? "")|\(stderrPath ?? "")|\(isFollowing)|\(emptyText)"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 8) {
                    if output.isTruncated {
                        Text("Showing the last \(LogFileSnapshot.byteLimitLabel).")
                            .font(.caption2)
                            .foregroundColor(AppTheme.terminalMuted)
                    }

                    Text(output.text)
                        .font(AppTheme.monoFont)
                        .foregroundColor(output.isError ? AppTheme.danger : AppTheme.terminalText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: true)

                    Color.clear
                        .frame(width: 1, height: 1)
                        .id(Self.bottomID)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.visible)
            .onChange(of: output.text) { _, _ in
                guard isFollowing else { return }
                proxy.scrollTo(Self.bottomID, anchor: .bottom)
            }
        }
        .task(id: taskID) {
            await streamLogs()
        }
    }

    @MainActor
    private func streamLogs() async {
        while !Task.isCancelled {
            let nextOutput = await TerminalLogOutput.load(
                stdoutPath: stdoutPath,
                stderrPath: stderrPath,
                emptyText: emptyText
            )
            guard !Task.isCancelled else { return }
            output = nextOutput

            guard isFollowing else { return }
            try? await Task.sleep(nanoseconds: 700_000_000)
        }
    }
}

struct TerminalLogOutput: Equatable, Sendable {
    var text: String
    var isTruncated: Bool
    var isError: Bool

    static func load(stdoutPath: String?, stderrPath: String?, emptyText: String) async -> TerminalLogOutput {
        let stdout = await snapshot(for: stdoutPath)
        let stderr = await snapshot(for: stderrPath)

        var chunks: [String] = []
        if stdout.kind == .content {
            chunks.append(stdout.text)
        }
        if stderr.kind == .content {
            chunks.append(stderr.text)
        }

        if !chunks.isEmpty {
            return TerminalLogOutput(
                text: chunks.joined(separator: "\n"),
                isTruncated: stdout.isTruncated || stderr.isTruncated,
                isError: false
            )
        }

        let errors = [stdout, stderr]
            .filter { $0.kind == .error }
            .map(\.text)
        if !errors.isEmpty {
            return TerminalLogOutput(
                text: errors.joined(separator: "\n"),
                isTruncated: false,
                isError: true
            )
        }

        if stdout.kind == .waiting || stderr.kind == .waiting {
            return TerminalLogOutput(text: "Waiting for log output...", isTruncated: false, isError: false)
        }

        if stdout.kind == .empty || stderr.kind == .empty {
            return TerminalLogOutput(text: "No output yet.", isTruncated: false, isError: false)
        }

        return TerminalLogOutput(text: emptyText, isTruncated: false, isError: false)
    }

    private static func snapshot(for path: String?) async -> LogFileSnapshot {
        guard let path, !path.isEmpty else { return .missingPath }
        return await LogFileSnapshot.load(path: path)
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
                .background(AppTheme.contentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                .foregroundColor(AppTheme.outline)
                .font(.system(size: 14, weight: .semibold))
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .innerFieldShadow()
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    var fill: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(fill ?? color.opacity(0.16))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var fill: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(fill ?? color.opacity(0.14))
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
        .background(AppTheme.detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
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
        .background(AppTheme.detailSurface)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 3)
    }
}

enum AppTheme {
    static let chromeHeight: CGFloat = 52

    static let windowSurface = Color(red: 246 / 255, green: 247 / 255, blue: 251 / 255)
    static let windowChromeSurface = Color(red: 248 / 255, green: 248 / 255, blue: 250 / 255)
    static let sidebarSurface = Color(red: 244 / 255, green: 246 / 255, blue: 250 / 255)
    static let sidebarSelectedSurface = Color(red: 230 / 255, green: 233 / 255, blue: 239 / 255)
    static let contentSurface = Color(red: 250 / 255, green: 251 / 255, blue: 253 / 255)
    static let detailSurface = Color.white
    static let fieldSurface = Color(red: 247 / 255, green: 248 / 255, blue: 250 / 255)
    static let surfaceSubtle = Color(red: 249 / 255, green: 250 / 255, blue: 252 / 255)
    static let surfaceContainer = Color(red: 238 / 255, green: 239 / 255, blue: 243 / 255)
    static let surfaceContainerHigh = Color(red: 226 / 255, green: 229 / 255, blue: 235 / 255)
    static let separator = Color(red: 225 / 255, green: 228 / 255, blue: 234 / 255)
    static let background = windowSurface
    static let panel = detailSurface

    static let onSurface = Color(red: 26 / 255, green: 28 / 255, blue: 29 / 255)
    static let onSurfaceVariant = Color(red: 65 / 255, green: 71 / 255, blue: 84 / 255)
    static let outline = Color(red: 143 / 255, green: 149 / 255, blue: 160 / 255)
    static let secondary = Color(red: 0 / 255, green: 102 / 255, blue: 135 / 255)

    static let accent = Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    static let selectionMark = Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    static let selectionSurface = Color(red: 231 / 255, green: 240 / 255, blue: 255 / 255)
    static let selectionStroke = Color(red: 174 / 255, green: 205 / 255, blue: 255 / 255)
    static let stoppedSurface = sidebarSurface
    static let errorSurface = Color(red: 255 / 255, green: 241 / 255, blue: 240 / 255)
    static let warningSurface = Color(red: 255 / 255, green: 247 / 255, blue: 230 / 255)
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let successSurface = Color(red: 224 / 255, green: 246 / 255, blue: 231 / 255)
    static let terminalChrome = Color(red: 31 / 255, green: 35 / 255, blue: 39 / 255)
    static let terminalSurface = Color(red: 18 / 255, green: 24 / 255, blue: 26 / 255)
    static let terminalText = Color(red: 232 / 255, green: 236 / 255, blue: 239 / 255)
    static let terminalMuted = Color(red: 139 / 255, green: 148 / 255, blue: 158 / 255)
    static let terminalAccent = Color(red: 40 / 255, green: 160 / 255, blue: 196 / 255)
    static let highlight = selectionMark
    static let warning = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    static let danger = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let labelFont = Font.system(size: 11, weight: .semibold)
    static let metadataFont = Font.system(size: 11, weight: .regular)
    static let monoSmallFont = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let monoFont = Font.system(size: 12, weight: .medium, design: .monospaced)
    static let sectionTitleFont = Font.system(size: 13, weight: .semibold)
    static let titleSmallFont = Font.system(size: 16, weight: .semibold)
    static let titleFont = Font.system(size: 20, weight: .semibold)
    static let sidebarTitleFont = Font.system(size: 14, weight: .semibold)
}

private struct InnerFieldShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.surfaceContainerHigh.opacity(0.7), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }
}

private extension View {
    func innerFieldShadow() -> some View {
        modifier(InnerFieldShadow())
    }
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
            return AppTheme.accent
        case .running:
            return AppTheme.success
        case .stopping:
            return AppTheme.warning
        case .stopped, .unknown:
            return AppTheme.outline
        case .error:
            return AppTheme.danger
        }
    }

    var fillColor: Color {
        switch self {
        case .pulling, .creating, .starting, .running:
            return self == .running ? AppTheme.successSurface : AppTheme.selectionSurface
        case .stopping:
            return AppTheme.warningSurface
        case .stopped, .unknown:
            return AppTheme.stoppedSurface
        case .error:
            return AppTheme.errorSurface
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
            return AppTheme.success
        case .stopping:
            return AppTheme.warning
        case .stopped:
            return AppTheme.outline
        case .unknown:
            return AppTheme.outline
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

extension OCIImageAvailability {
    var label: String {
        switch self {
        case .downloaded:
            return "Downloaded"
        case .added:
            return "Added"
        case .pulling:
            return "Pulling"
        }
    }

    var color: Color {
        switch self {
        case .downloaded, .pulling:
            return AppTheme.accent
        case .added:
            return AppTheme.warning
        }
    }

    var fillColor: Color {
        switch self {
        case .downloaded, .pulling:
            return AppTheme.selectionSurface
        case .added:
            return AppTheme.warningSurface
        }
    }
}

extension OCIImageRecord {
    var builtInLabel: String {
        "Built-in"
    }

    var canDeleteOrRemove: Bool {
        !isBuiltIn || isDownloaded
    }

    var destructiveActionTitle: String {
        isDownloaded ? "Delete Image" : "Remove Image"
    }

    func matchesBuiltInSearch(_ query: String) -> Bool {
        guard isBuiltIn else { return false }
        return builtInLabel.localizedCaseInsensitiveContains(query) ||
            "builtin".localizedCaseInsensitiveContains(query) ||
            "内置".localizedCaseInsensitiveContains(query)
    }

    var shortDigest: String {
        digest.isEmpty ? "—" : (digest.count > 18 ? String(digest.prefix(18)) + "…" : digest)
    }

    var platformLabel: String {
        platforms.joined(separator: ", ")
    }

    var usageDescription: String {
        if isBuiltIn {
            switch availability {
            case .downloaded:
                return "Use this built-in image directly in a new sandbox."
            case .pulling:
                return "This built-in image is being pulled. It will be available for new sandboxes after the download finishes."
            case .added:
                return "Pull this built-in image before creating a sandbox from it."
            }
        }

        switch availability {
        case .downloaded:
            return "Use this downloaded image directly in a new sandbox."
        case .pulling:
            return "This image is being pulled. It will be available for new sandboxes after the download finishes."
        case .added:
            return "Pull this reference before creating a sandbox from it."
        }
    }
}

extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }

    var shortDigest: String {
        count > 18 ? String(prefix(18)) + "..." : self
    }
}

extension Date {
    var compactRelativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
