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

struct OCIImageRecord: Identifiable, Hashable {
    let reference: String
    let digest: String
    let mediaType: String

    var id: String { reference }
}

struct SandboxRecord: Identifiable, Hashable {
    let id: String
    var name: String
    var imageReference: String
    var imageDigest: String
    var runtimeHandler: String
    var platform: String
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
    var autoStart: Bool
}

struct ImagePullDraft: Hashable {
    var reference: String = ""
}

struct WorkloadDraft: Hashable {
    var sandboxID: String
    var shellCommand: String
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
    @Published var selectedImageReference: String?
    @Published var systemStatus: SystemStatus = .unavailable
    @Published var images: [OCIImageRecord] = []
    @Published var sandboxes: [SandboxRecord] = []
    @Published var sandboxDetails: [String: SandboxDetail] = [:]
    @Published var banner: AppBanner?
    @Published var isRefreshing = false
    @Published var isMutating = false
    @Published var activityMessage: String?

    private let service: ContainerSDKService
    private var hasLoadedOnce = false

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

    var selectedSandboxDetail: SandboxDetail? {
        guard let selectedSandboxID else { return nil }
        return sandboxDetails[selectedSandboxID]
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
        } catch {
            sandboxes = []
            sandboxDetails = [:]
            showError(title: "Failed to load sandboxes", error: error)
        }

        reconcileSelections()
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
            reconcileSelections()
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

    func deleteImage(reference: String) {
        runMutation(activity: "Deleting \(reference)") { [service] in
            try await service.deleteImage(reference: reference)
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
                message: "The sandbox must be created from a pulled or pullable OCI image.",
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

    func removeSandbox(_ sandboxID: String) {
        guard let sandbox = sandboxes.first(where: { $0.id == sandboxID }) else { return }
        runMutation(activity: "Removing \(sandbox.name)") { [service] in
            try await service.removeSandbox(id: sandboxID)
            if self.selectedSandboxID == sandboxID {
                self.selectedSandboxID = nil
            }
            await self.refreshAll()
        }
    }

    func runWorkload(_ draft: WorkloadDraft) {
        let trimmedCommand = draft.shellCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWorkingDirectory = draft.workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCommand.isEmpty else {
            banner = AppBanner(
                title: "Missing command",
                message: "Enter a shell command to run inside the sandbox.",
                style: .error
            )
            return
        }

        let normalizedDraft = WorkloadDraft(
            sandboxID: draft.sandboxID,
            shellCommand: trimmedCommand,
            workingDirectory: trimmedWorkingDirectory.isEmpty ? "/" : trimmedWorkingDirectory
        )

        runMutation(activity: "Running command in \(draft.sandboxID)") { [service] in
            _ = try await service.runWorkload(from: normalizedDraft)
            await self.refreshAll()
            self.selectedSidebar = .sandboxes
            self.selectedSandboxID = draft.sandboxID
        }
    }

    func stopWorkload(sandboxID: String, workloadID: String) {
        runMutation(activity: "Stopping workload \(workloadID)") { [service] in
            try await service.stopWorkload(sandboxID: sandboxID, workloadID: workloadID)
            await self.refreshAll()
        }
    }

    func removeWorkload(sandboxID: String, workloadID: String) {
        runMutation(activity: "Removing workload \(workloadID)") { [service] in
            try await service.removeWorkload(sandboxID: sandboxID, workloadID: workloadID)
            await self.refreshAll()
        }
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

    private func reconcileSelections() {
        if let selectedSandboxID, !sandboxes.contains(where: { $0.id == selectedSandboxID }) {
            self.selectedSandboxID = nil
        }
        if let selectedImageReference, !images.contains(where: { $0.reference == selectedImageReference }) {
            self.selectedImageReference = nil
        }
        if selectedSandboxID == nil {
            selectedSandboxID = sandboxes.first?.id
        }
        if selectedImageReference == nil {
            selectedImageReference = images.first?.reference
        }
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
