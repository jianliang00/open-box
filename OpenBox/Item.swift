//
//  Item.swift
//  OpenBox
//
//  Created by jianliang on 2026/1/24.
//

import Foundation

enum SidebarSection: String, CaseIterable, Identifiable {
    case sandboxes = "Sandboxes"
    case images = "Images"
    case settings = "Settings"

    var id: String { rawValue }
}

enum FileShareMode: String, CaseIterable, Identifiable, Hashable {
    case readWrite = "rw"
    case readOnly = "ro"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .readWrite:
            return "Read/Write"
        case .readOnly:
            return "Read Only"
        }
    }

    var mountOptions: [String] {
        switch self {
        case .readWrite:
            return []
        case .readOnly:
            return ["ro"]
        }
    }
}

enum SandboxStatus: String, CaseIterable, Identifiable, Hashable {
    case unknown
    case pulling
    case creating
    case starting
    case running
    case stopping
    case stopped
    case error

    var id: String { rawValue }

    init(runtimeRawValue: String) {
        switch runtimeRawValue.lowercased() {
        case "running":
            self = .running
        case "stopping":
            self = .stopping
        case "stopped":
            self = .stopped
        default:
            self = .unknown
        }
    }
}

enum WorkloadStatus: String, CaseIterable, Identifiable, Hashable {
    case unknown
    case running
    case stopping
    case stopped

    var id: String { rawValue }

    init(runtimeRawValue: String) {
        switch runtimeRawValue.lowercased() {
        case "running":
            self = .running
        case "stopping":
            self = .stopping
        case "stopped":
            self = .stopped
        default:
            self = .unknown
        }
    }
}

enum OCIImageAvailability: String, Codable, Hashable {
    case downloaded
    case added
}

struct OCIImageRecord: Identifiable, Hashable {
    let reference: String
    let digest: String
    let mediaType: String
    let availability: OCIImageAvailability
    let platforms: [String]

    init(
        reference: String,
        digest: String,
        mediaType: String,
        availability: OCIImageAvailability = .downloaded,
        platforms: [String] = []
    ) {
        self.reference = reference
        self.digest = digest
        self.mediaType = mediaType
        self.availability = availability
        self.platforms = platforms
    }

    var id: String { reference }

    var isDownloaded: Bool {
        availability == .downloaded
    }
}

struct SandboxRecord: Identifiable, Hashable {
    let id: String
    var name: String
    var imageReference: String
    var imageDigest: String
    var runtimeHandler: String
    var platform: String
    var desktopGUIEnabled: Bool
    var status: SandboxStatus
    var cpuCores: Int
    var memoryGB: Int
    var diskGB: Int?
    var workspacePath: String?
    var shareMode: FileShareMode?
    var startedAt: Date?
    var workloadCount: Int
    var lastError: String?
    var labels: [String: String]

    var isMacOSGuest: Bool {
        runtimeHandler == "container-runtime-macos"
    }

    var guestWorkspacePath: String {
        isMacOSGuest ? "/Users/Shared/workspace" : "/workspace"
    }

    var shellPath: String {
        isMacOSGuest ? "/bin/zsh" : "/bin/sh"
    }
}

struct SandboxNetworkRecord: Identifiable, Hashable {
    let id: String
    var networkID: String
    var hostname: String
    var ipv4Address: String
    var gateway: String
    var dnsServers: [String]
}

struct SandboxLogRecord: Hashable {
    var eventLogPath: String
    var bootLogPath: String
    var guestAgentLogPath: String?
    var guestAgentStderrLogPath: String?
}

struct WorkloadRecord: Identifiable, Hashable {
    let id: String
    var command: String
    var workingDirectory: String
    var status: WorkloadStatus
    var exitCode: Int32?
    var stdoutLogPath: String?
    var stderrLogPath: String?
    var startedAt: Date?
    var exitedAt: Date?
    var isImageBacked: Bool
    var isTerminal: Bool
}

struct SandboxDetail: Hashable {
    let sandboxID: String
    var networks: [SandboxNetworkRecord]
    var workloads: [WorkloadRecord]
    var logPaths: SandboxLogRecord?
    var lastError: String?
}

struct SystemStatus: Hashable {
    var isAvailable: Bool
    var version: String?
    var build: String?
    var appRoot: String?
    var installRoot: String?
    var lastError: String?

    static let unavailable = SystemStatus(
        isAvailable: false,
        version: nil,
        build: nil,
        appRoot: nil,
        installRoot: nil,
        lastError: nil
    )
}

struct SandboxDraft: Hashable {
    var name: String
    var imageReference: String
    var cpuCores: Int
    var memoryGB: Int
    var diskGB: Int
    var workspacePath: String
    var shareMode: FileShareMode
    var desktopGUIEnabled: Bool
    var autoStart: Bool
}

struct ImagePullDraft: Hashable {
    var reference: String = ""
}

enum WorkloadRunMode: String, CaseIterable, Identifiable, Hashable {
    case command
    case interactiveShell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .command:
            return "Command"
        case .interactiveShell:
            return "Interactive Shell"
        }
    }
}

struct WorkloadDraft: Hashable {
    var sandboxID: String
    var mode: WorkloadRunMode
    var shellCommand: String
    var shellPath: String
    var workingDirectory: String
}

enum BannerStyle: Hashable {
    case info
    case error
}

struct AppBanner: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var message: String
    var style: BannerStyle
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSidebar: SidebarSection = .sandboxes
    @Published var selectedSandboxID: String?
    @Published var selectedWorkloadID: String?
    @Published var selectedImageReference: String?
    @Published var systemStatus: SystemStatus = .unavailable
    @Published var images: [OCIImageRecord] = []
    @Published var sandboxes: [SandboxRecord] = []
    @Published var sandboxDetails: [String: SandboxDetail] = [:]
    @Published var banner: AppBanner?
    @Published var isRefreshing = false
    @Published var isMutating = false
    @Published var activityMessage: String?
    @Published private var interactiveTerminalIO: [String: InteractiveWorkloadIO] = [:]

    private let service: ContainerSDKService
    private var hasLoadedOnce = false
    private var transientWorkloads: [String: [WorkloadRecord]] = [:]

    init(service: ContainerSDKService = ContainerSDKService()) {
        self.service = service
    }

    var selectedSandbox: SandboxRecord? {
        guard let selectedSandboxID else { return nil }
        return sandboxes.first { $0.id == selectedSandboxID }
    }

    var selectedImage: OCIImageRecord? {
        guard let selectedImageReference else { return nil }
        return images.first { $0.reference == selectedImageReference }
    }

    var downloadedImages: [OCIImageRecord] {
        images.filter(\.isDownloaded)
    }

    var selectedSandboxDetail: SandboxDetail? {
        guard let selectedSandboxID else { return nil }
        return sandboxDetails[selectedSandboxID]
    }

    var selectedWorkload: WorkloadRecord? {
        guard let selectedWorkloadID else { return nil }
        return selectedSandboxDetail?.workloads.first { $0.id == selectedWorkloadID }
    }

    func clearBanner() {
        banner = nil
    }

    func refreshAllIfNeeded() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        await refreshAll()
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            systemStatus = try await service.systemStatus()
        } catch {
            systemStatus = SystemStatus(
                isAvailable: false,
                version: nil,
                build: nil,
                appRoot: nil,
                installRoot: nil,
                lastError: error.openBoxMessage
            )
            images = []
            sandboxes = []
            sandboxDetails = [:]
            reconcileSelections()
            reconcileInteractiveTerminalIO()
            return
        }

        do {
            images = try await service.loadImages()
        } catch {
            images = []
            showError(title: "Failed to load images", error: error)
        }

        do {
            let inventory = try await service.loadSandboxes()
            sandboxes = inventory.sandboxes
            sandboxDetails = inventory.details
            mergeTransientWorkloads()
        } catch {
            sandboxes = []
            sandboxDetails = [:]
            showError(title: "Failed to load sandboxes", error: error)
        }

        reconcileSelections()
        reconcileInteractiveTerminalIO()
    }

    func refreshSandbox(id: String) async {
        guard !isRefreshing else { return }

        do {
            let sandbox = try await service.loadSandbox(id: id)
            if let index = sandboxes.firstIndex(where: { $0.id == sandbox.record.id }) {
                sandboxes[index] = sandbox.record
            } else {
                sandboxes.append(sandbox.record)
            }
            sandboxDetails[sandbox.record.id] = sandbox.detail
            mergeTransientWorkloads()
            reconcileSelections()
            reconcileInteractiveTerminalIO()
        } catch {
            await refreshAll()
        }
    }

    func pullImage(reference: String) {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            banner = AppBanner(
                title: "Missing image reference",
                message: "Enter an OCI image reference like ghcr.io/org/image:tag.",
                style: .error
            )
            return
        }

        runMutation(activity: "Pulling \(trimmed)") { [service] in
            let image = try await service.pullImage(reference: trimmed)
            await self.refreshAll()
            self.selectedSidebar = .images
            self.selectedImageReference = self.images.first(where: { $0.reference == image.reference })?.reference ?? image.reference
        }
    }

    func addImageReference(reference: String) {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            banner = AppBanner(
                title: "Missing image reference",
                message: "Enter an OCI image reference like ghcr.io/org/image:tag.",
                style: .error
            )
            return
        }

        runMutation(activity: "Adding \(trimmed)") { [service] in
            try await service.addImageReference(reference: trimmed)
            await self.refreshAll()
            self.selectedSidebar = .images
            self.selectedImageReference = trimmed
        }
    }

    func deleteImage(reference: String) {
        let image = images.first { $0.reference == reference }
        let deleteDownloadedImage = image?.isDownloaded == true
        let activity = deleteDownloadedImage ? "Deleting \(reference)" : "Removing \(reference)"

        runMutation(activity: activity) { [service] in
            try await service.deleteImage(reference: reference, deleteDownloadedImage: deleteDownloadedImage)
            if self.selectedImageReference == reference {
                self.selectedImageReference = nil
            }
            await self.refreshAll()
        }
    }

    func createSandbox(from draft: SandboxDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReference = draft.imageReference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            banner = AppBanner(
                title: "Missing sandbox name",
                message: "Choose a readable name for the sandbox.",
                style: .error
            )
            return
        }
        guard !trimmedReference.isEmpty else {
            banner = AppBanner(
                title: "Missing OCI image reference",
                message: "Choose a downloaded OCI image before creating the sandbox.",
                style: .error
            )
            return
        }
        guard images.contains(where: { $0.reference == trimmedReference && $0.isDownloaded }) else {
            banner = AppBanner(
                title: "Image is not downloaded",
                message: "New sandboxes can only be created from images that are already downloaded locally.",
                style: .error
            )
            return
        }

        let normalizedDraft: SandboxDraft = {
            var draft = draft
            draft.name = trimmedName
            draft.imageReference = trimmedReference
            return draft
        }()

        runMutation(activity: "Creating sandbox \(trimmedName)") { [service] in
            let sandboxID = try await service.createSandbox(from: normalizedDraft)
            await self.refreshAll()
            self.selectedSidebar = .sandboxes
            self.selectedSandboxID = sandboxID
            self.selectedWorkloadID = nil
        }
    }

    func toggleSandbox(_ sandboxID: String) {
        guard let sandbox = sandboxes.first(where: { $0.id == sandboxID }) else { return }
        switch sandbox.status {
        case .running:
            mutateSandbox(id: sandboxID) { $0.status = .stopping }
            runMutation(activity: "Stopping \(sandbox.name)") { [service] in
                try await service.stopSandbox(id: sandboxID)
                await self.refreshAll()
            }
        case .stopped, .unknown, .error:
            mutateSandbox(id: sandboxID) { $0.status = .starting }
            runMutation(activity: "Starting \(sandbox.name)") { [service] in
                try await service.startSandbox(id: sandboxID)
                await self.refreshAll()
            }
        case .pulling, .creating, .starting, .stopping:
            return
        }
    }

    func launchDesktop(for sandboxID: String) {
        guard let sandbox = sandboxes.first(where: { $0.id == sandboxID }) else { return }
        guard sandbox.isMacOSGuest else {
            banner = AppBanner(
                title: "Desktop unavailable",
                message: "Desktop GUI is supported only for macOS guest sandboxes in this MVP.",
                style: .error
            )
            return
        }
        guard sandbox.desktopGUIEnabled else {
            banner = AppBanner(
                title: "Desktop GUI is not enabled",
                message: "Create a new macOS guest sandbox with Enable desktop GUI turned on. Existing sandboxes cannot be switched to GUI mode safely.",
                style: .error
            )
            return
        }

        switch sandbox.status {
        case .running:
            runMutation(activity: "Opening desktop \(sandbox.name)") { [service] in
                try await service.launchDesktop(id: sandboxID)
                await self.refreshAll()
                self.banner = AppBanner(
                    title: "Desktop opened",
                    message: "The desktop window is open for \(sandbox.name). Closing the window leaves the sandbox running.",
                    style: .info
                )
            }
        case .stopped, .unknown, .error:
            mutateSandbox(id: sandboxID) { $0.status = .starting }
            runMutation(activity: "Launching desktop \(sandbox.name)") { [service] in
                try await service.launchDesktop(id: sandboxID)
                await self.refreshAll()
                self.banner = AppBanner(
                    title: "Desktop launched",
                    message: "The runtime started \(sandbox.name) and opened its desktop window.",
                    style: .info
                )
            }
        case .pulling, .creating, .starting, .stopping:
            banner = AppBanner(
                title: "Desktop is busy",
                message: "Wait until the sandbox finishes its current transition, then launch the desktop again.",
                style: .info
            )
        }
    }

    func removeSandbox(_ sandboxID: String) {
        guard let sandbox = sandboxes.first(where: { $0.id == sandboxID }) else { return }
        runMutation(activity: "Removing \(sandbox.name)") { [service] in
            try await service.removeSandbox(id: sandboxID)
            if self.selectedSandboxID == sandboxID {
                self.selectedSandboxID = nil
                self.selectedWorkloadID = nil
            }
            self.transientWorkloads[sandboxID] = nil
            await self.refreshAll()
        }
    }

    func runWorkload(_ draft: WorkloadDraft) {
        let trimmedCommand = draft.shellCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedShellPath = draft.shellPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWorkingDirectory = draft.workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.mode == .command, trimmedCommand.isEmpty {
            banner = AppBanner(
                title: "Missing command",
                message: "Enter a shell command to run inside the sandbox.",
                style: .error
            )
            return
        }
        if draft.mode == .interactiveShell, trimmedShellPath.isEmpty {
            banner = AppBanner(
                title: "Missing shell",
                message: "Enter a shell executable path like /bin/zsh or /bin/bash.",
                style: .error
            )
            return
        }

        let normalizedDraft = WorkloadDraft(
            sandboxID: draft.sandboxID,
            mode: draft.mode,
            shellCommand: trimmedCommand,
            shellPath: trimmedShellPath,
            workingDirectory: trimmedWorkingDirectory.isEmpty ? "/" : trimmedWorkingDirectory
        )

        let activity = draft.mode == .interactiveShell
            ? "Starting shell in \(draft.sandboxID)"
            : "Running command in \(draft.sandboxID)"

        runMutation(activity: activity) { [service] in
            let launch = try await service.runWorkload(from: normalizedDraft)
            if let terminalIO = launch.terminalIO {
                self.interactiveTerminalIO[self.interactiveTerminalKey(sandboxID: draft.sandboxID, workloadID: launch.workloadID)] = terminalIO
            }
            await self.refreshAll()
            if let workload = launch.workload {
                self.addTransientWorkload(workload, sandboxID: draft.sandboxID)
                self.mergeTransientWorkloads()
            }
            self.selectedSidebar = .sandboxes
            self.selectedSandboxID = draft.sandboxID
            self.selectedWorkloadID = self.sandboxDetails[draft.sandboxID]?.workloads.contains {
                $0.id == launch.workloadID
            } == true ? launch.workloadID : nil
        }
    }

    func stopWorkload(sandboxID: String, workloadID: String) {
        runMutation(activity: "Stopping workload \(workloadID)") { [service] in
            try await service.stopWorkload(sandboxID: sandboxID, workloadID: workloadID)
            self.closeInteractiveTerminalIO(sandboxID: sandboxID, workloadID: workloadID)
            await self.refreshAll()
        }
    }

    func removeWorkload(sandboxID: String, workloadID: String) {
        if removeTransientWorkload(sandboxID: sandboxID, workloadID: workloadID) {
            if selectedSandboxID == sandboxID, selectedWorkloadID == workloadID {
                selectedWorkloadID = nil
            }
            return
        }

        runMutation(activity: "Removing workload \(workloadID)") { [service] in
            try await service.removeWorkload(sandboxID: sandboxID, workloadID: workloadID)
            self.closeInteractiveTerminalIO(sandboxID: sandboxID, workloadID: workloadID)
            if self.selectedSandboxID == sandboxID, self.selectedWorkloadID == workloadID {
                self.selectedWorkloadID = nil
            }
            await self.refreshAll()
        }
    }

    func interactiveTerminal(sandboxID: String, workloadID: String) -> InteractiveWorkloadIO? {
        interactiveTerminalIO[interactiveTerminalKey(sandboxID: sandboxID, workloadID: workloadID)]
    }

    func resizeInteractiveTerminal(sandboxID: String, workloadID: String, columns: Int, rows: Int) {
        guard columns > 0, rows > 0 else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await service.resizeTerminal(
                    sandboxID: sandboxID,
                    workloadID: workloadID,
                    columns: columns,
                    rows: rows
                )
            } catch {
                self.showError(title: "Failed to resize terminal", error: error)
            }
        }
    }

    func showInteractiveTerminalError(_ error: Error) {
        showError(title: "Terminal I/O failed", error: error)
    }

    private func runMutation(
        activity: String,
        operation: @escaping @MainActor @Sendable () async throws -> Void
    ) {
        guard !isMutating else { return }
        isMutating = true
        activityMessage = activity
        banner = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.isMutating = false
                self.activityMessage = nil
            }

            do {
                try await operation()
            } catch {
                self.showError(title: activity, error: error)
            }
        }
    }

    private func mutateSandbox(id: String, _ mutate: (inout SandboxRecord) -> Void) {
        guard let index = sandboxes.firstIndex(where: { $0.id == id }) else { return }
        var sandbox = sandboxes[index]
        mutate(&sandbox)
        sandboxes[index] = sandbox
    }

    private func addTransientWorkload(_ workload: WorkloadRecord, sandboxID: String) {
        var workloads = transientWorkloads[sandboxID] ?? []
        workloads.removeAll { $0.id == workload.id }
        workloads.insert(workload, at: 0)
        transientWorkloads[sandboxID] = Array(workloads.prefix(20))
    }

    private func removeTransientWorkload(sandboxID: String, workloadID: String) -> Bool {
        guard var workloads = transientWorkloads[sandboxID],
              workloads.contains(where: { $0.id == workloadID }) else {
            return false
        }

        workloads.removeAll { $0.id == workloadID }
        transientWorkloads[sandboxID] = workloads.isEmpty ? nil : workloads
        if var detail = sandboxDetails[sandboxID] {
            detail.workloads.removeAll { $0.id == workloadID }
            sandboxDetails[sandboxID] = detail
            if let index = sandboxes.firstIndex(where: { $0.id == sandboxID }) {
                sandboxes[index].workloadCount = detail.workloads.count
            }
        }
        return true
    }

    private func mergeTransientWorkloads() {
        let knownSandboxIDs = Set(sandboxes.map(\.id))
        transientWorkloads = transientWorkloads.filter { knownSandboxIDs.contains($0.key) }

        for (sandboxID, transientRecords) in transientWorkloads {
            var detail = sandboxDetails[sandboxID] ?? SandboxDetail(
                sandboxID: sandboxID,
                networks: [],
                workloads: [],
                logPaths: nil,
                lastError: nil
            )
            let persistentIDs = Set(detail.workloads.map(\.id))
            let missingTransientRecords = transientRecords.filter { !persistentIDs.contains($0.id) }
            guard !missingTransientRecords.isEmpty else { continue }

            detail.workloads = (missingTransientRecords + detail.workloads).sorted {
                $0.startedAt ?? .distantPast > $1.startedAt ?? .distantPast
            }
            sandboxDetails[sandboxID] = detail

            if let index = sandboxes.firstIndex(where: { $0.id == sandboxID }) {
                sandboxes[index].workloadCount = detail.workloads.count
            }
        }
    }

    private func reconcileSelections() {
        if let selectedSandboxID, !sandboxes.contains(where: { $0.id == selectedSandboxID }) {
            self.selectedSandboxID = nil
            self.selectedWorkloadID = nil
        }
        if let selectedImageReference, !images.contains(where: { $0.reference == selectedImageReference }) {
            self.selectedImageReference = nil
        }
        if selectedSandboxID == nil {
            selectedSandboxID = sandboxes.first?.id
        }
        if let selectedWorkloadID,
           selectedSandboxDetail?.workloads.contains(where: { $0.id == selectedWorkloadID }) != true {
            self.selectedWorkloadID = nil
        }
        if selectedImageReference == nil {
            selectedImageReference = images.first?.reference
        }
    }

    private func reconcileInteractiveTerminalIO() {
        let knownSandboxIDs = Set(sandboxes.map(\.id))

        for key in Array(interactiveTerminalIO.keys) {
            guard let ids = interactiveTerminalIDs(from: key),
                  knownSandboxIDs.contains(ids.sandboxID) else {
                interactiveTerminalIO.removeValue(forKey: key)?.close()
                continue
            }

            guard let detail = sandboxDetails[ids.sandboxID],
                  let workload = detail.workloads.first(where: { $0.id == ids.workloadID }) else {
                continue
            }

            if workload.status != .running {
                interactiveTerminalIO.removeValue(forKey: key)?.close()
            }
        }
    }

    private func closeInteractiveTerminalIO(sandboxID: String, workloadID: String) {
        interactiveTerminalIO.removeValue(forKey: interactiveTerminalKey(sandboxID: sandboxID, workloadID: workloadID))?.close()
    }

    private func interactiveTerminalKey(sandboxID: String, workloadID: String) -> String {
        "\(sandboxID)|\(workloadID)"
    }

    private func interactiveTerminalIDs(from key: String) -> (sandboxID: String, workloadID: String)? {
        guard let separator = key.firstIndex(of: "|") else { return nil }
        let workloadStart = key.index(after: separator)
        let sandboxID = String(key[..<separator])
        let workloadID = String(key[workloadStart...])
        guard !sandboxID.isEmpty, !workloadID.isEmpty else { return nil }
        return (sandboxID, workloadID)
    }

    private func showError(title: String, error: Error) {
        banner = AppBanner(
            title: title,
            message: error.openBoxMessage,
            style: .error
        )
    }
}

extension Error {
    var openBoxMessage: String {
        if let localizedError = self as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            return description
        }

        let detailed = String(describing: self)
        let localized = localizedDescription
        if !detailed.isEmpty, detailed != localized {
            return detailed
        }

        let nsError = self as NSError
        if !nsError.domain.isEmpty {
            return "\(localized) (\(nsError.domain) code \(nsError.code))"
        }

        return localized
    }
}
