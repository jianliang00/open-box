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
    case pulling
}

enum BuiltInImageCatalog {
    static let macOSBaseReference = "ghcr.io/jianliang00/macos-base:26.3"
    static let references = [macOSBaseReference]

    private static let referenceSet = Set(references)

    static func contains(_ reference: String) -> Bool {
        referenceSet.contains(reference.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct OCIImageRecord: Identifiable, Hashable {
    let reference: String
    let digest: String
    let mediaType: String
    let availability: OCIImageAvailability
    let platforms: [String]
    let isBuiltIn: Bool

    init(
        reference: String,
        digest: String,
        mediaType: String,
        availability: OCIImageAvailability = .downloaded,
        platforms: [String] = [],
        isBuiltIn: Bool = false
    ) {
        self.reference = reference
        self.digest = digest
        self.mediaType = mediaType
        self.availability = availability
        self.platforms = platforms
        self.isBuiltIn = isBuiltIn
    }

    var id: String { reference }

    static func displayOrder(lhs: OCIImageRecord, rhs: OCIImageRecord) -> Bool {
        if lhs.isBuiltIn != rhs.isBuiltIn {
            return lhs.isBuiltIn
        }
        return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
    }

    var isDownloaded: Bool {
        availability == .downloaded
    }

    var isPulling: Bool {
        availability == .pulling
    }
}

struct ImagePullProgress: Hashable, Sendable {
    var reference: String
    private(set) var downloadedBytes: Int64
    private(set) var totalBytes: Int64
    private(set) var completedItems: Int64
    private(set) var totalItems: Int64
    private(set) var isCancelling: Bool

    init(
        reference: String,
        downloadedBytes: Int64 = 0,
        totalBytes: Int64 = 0,
        completedItems: Int64 = 0,
        totalItems: Int64 = 0,
        isCancelling: Bool = false
    ) {
        self.reference = reference
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.isCancelling = isCancelling
    }

    var fractionCompleted: Double? {
        if totalBytes > 0 {
            return min(1, max(0, Double(downloadedBytes) / Double(totalBytes)))
        }
        if totalItems > 0 {
            return min(1, max(0, Double(completedItems) / Double(totalItems)))
        }
        return nil
    }

    var summary: String {
        if isCancelling {
            return "Cancelling..."
        }
        if totalBytes > 0 {
            return "\(percentLabel) · \(Self.byteCountString(downloadedBytes)) of \(Self.byteCountString(totalBytes))"
        }
        if downloadedBytes > 0 {
            return "\(Self.byteCountString(downloadedBytes)) downloaded"
        }
        if totalItems > 0 {
            return "\(completedItems) of \(totalItems) items"
        }
        return "Waiting for registry"
    }

    var percentLabel: String {
        guard let fractionCompleted else { return "0%" }
        return "\(Int((fractionCompleted * 100).rounded(.down)))%"
    }

    mutating func apply(event: String, value: Int64) {
        switch event {
        case "add-size":
            downloadedBytes = max(0, downloadedBytes + value)
        case "add-total-size":
            totalBytes = max(0, totalBytes + value)
        case "add-items":
            completedItems = max(0, completedItems + value)
        case "add-total-items":
            totalItems = max(0, totalItems + value)
        default:
            break
        }
    }

    mutating func markCancelling() {
        isCancelling = true
    }

    private static func byteCountString(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: byteCount)
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

enum SystemConnectionState: Hashable {
    case connecting
    case available
    case unavailable
}

struct SystemStatus: Hashable {
    var state: SystemConnectionState
    var version: String?
    var build: String?
    var appRoot: String?
    var installRoot: String?
    var lastError: String?

    var isAvailable: Bool {
        state == .available
    }

    var isConnecting: Bool {
        state == .connecting
    }

    var needsServiceNotice: Bool {
        state != .available
    }

    init(
        state: SystemConnectionState,
        version: String?,
        build: String?,
        appRoot: String?,
        installRoot: String?,
        lastError: String?
    ) {
        self.state = state
        self.version = version
        self.build = build
        self.appRoot = appRoot
        self.installRoot = installRoot
        self.lastError = lastError
    }

    init(
        isAvailable: Bool,
        version: String?,
        build: String?,
        appRoot: String?,
        installRoot: String?,
        lastError: String?
    ) {
        self.init(
            state: isAvailable ? .available : .unavailable,
            version: version,
            build: build,
            appRoot: appRoot,
            installRoot: installRoot,
            lastError: lastError
        )
    }

    func connecting() -> SystemStatus {
        SystemStatus(
            state: .connecting,
            version: version,
            build: build,
            appRoot: appRoot,
            installRoot: installRoot,
            lastError: nil
        )
    }

    static let connecting = SystemStatus(
        state: .connecting,
        version: nil,
        build: nil,
        appRoot: nil,
        installRoot: nil,
        lastError: nil
    )

    static let unavailable = SystemStatus(
        state: .unavailable,
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
    var usesRegistryCredentials = false
    var registryUsername = ""
    var registryToken = ""

    var registryHost: String? {
        ContainerSDKService.registryHost(forImageReference: reference)
    }

    var registryCredentials: RegistryCredentials? {
        guard usesRegistryCredentials,
              let host = registryHost else {
            return nil
        }

        return RegistryCredentials(
            host: host,
            username: registryUsername.trimmingCharacters(in: .whitespacesAndNewlines),
            token: registryToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    var canPull: Bool {
        let hasReference = !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasReference, usesRegistryCredentials else {
            return hasReference
        }

        return registryHost != nil &&
            !registryUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !registryToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
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
    @Published var systemStatus: SystemStatus = .connecting
    @Published var images: [OCIImageRecord] = []
    @Published var sandboxes: [SandboxRecord] = []
    @Published var sandboxDetails: [String: SandboxDetail] = [:]
    @Published var banner: AppBanner?
    @Published var isRefreshing = false
    @Published var isMutating = false
    @Published var activityMessage: String?
    @Published private var imagePulls: [String: ImagePullProgress] = [:]
    @Published private var interactiveTerminalIO: [String: InteractiveWorkloadIO] = [:]

    private let service: ContainerSDKService
    private var hasLoadedOnce = false
    private var transientWorkloads: [String: [WorkloadRecord]] = [:]
    private var imagePullTasks: [String: Task<Void, Never>] = [:]

    init(service: ContainerSDKService = ContainerSDKService()) {
        self.service = service
    }

    var selectedSandbox: SandboxRecord? {
        guard let selectedSandboxID else { return nil }
        return sandboxes.first { $0.id == selectedSandboxID }
    }

    var selectedImage: OCIImageRecord? {
        guard let selectedImageReference else { return nil }
        return displayedImages.first { $0.reference == selectedImageReference } ??
            displayedImages.first {
                ContainerSDKService.imageReferencesMatch($0.reference, selectedImageReference)
            }
    }

    var downloadedImages: [OCIImageRecord] {
        displayedImages.filter(\.isDownloaded)
    }

    var displayedImages: [OCIImageRecord] {
        let pullingReferences = Set(imagePulls.keys.map { ContainerSDKService.imageReferenceKey($0) })
        let persistentImages = images.map { image in
            guard pullingReferences.contains(ContainerSDKService.imageReferenceKey(image.reference)) else {
                return image
            }
            return OCIImageRecord(
                reference: image.reference,
                digest: image.digest,
                mediaType: image.mediaType,
                availability: .pulling,
                platforms: image.platforms,
                isBuiltIn: image.isBuiltIn
            )
        }

        let persistentReferences = Set(persistentImages.map { ContainerSDKService.imageReferenceKey($0.reference) })
        let transientImages = imagePulls.values
            .filter {
                !persistentReferences.contains(ContainerSDKService.imageReferenceKey($0.reference)) &&
                    !ContainerSDKService.isInternalRuntimeImageReference($0.reference)
            }
            .map {
                OCIImageRecord(
                    reference: $0.reference,
                    digest: "",
                    mediaType: "Pull in progress",
                    availability: .pulling,
                    isBuiltIn: BuiltInImageCatalog.contains($0.reference)
                )
            }

        return ContainerSDKService.userVisibleImageRecords(persistentImages + transientImages)
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
        systemStatus = systemStatus.connecting()
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

    func pullImage(reference: String, credentials: RegistryCredentials? = nil) {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            banner = AppBanner(
                title: "Missing image reference",
                message: "Enter an OCI image reference like ghcr.io/org/image:tag.",
                style: .error
            )
            return
        }
        let pullKey = imagePullKey(for: trimmed)
        if imagePullTasks[pullKey] != nil {
            selectedSidebar = .images
            selectedImageReference = displayedImages.first {
                ContainerSDKService.imageReferencesMatch($0.reference, trimmed)
            }?.reference ?? trimmed
            return
        }
        guard !isMutating else { return }

        startImagePull(reference: trimmed)

        let task = runMutation(activity: "Pulling \(trimmed)") { [service] in
            defer {
                self.finishImagePull(reference: trimmed)
            }

            do {
                let image = try await service.pullImage(reference: trimmed, credentials: credentials) { progress in
                    await MainActor.run {
                        self.updateImagePull(progress)
                    }
                }
                self.finishImagePull(reference: trimmed)
                await self.refreshAll()
                self.selectedSidebar = .images
                self.selectedImageReference = self.displayedImages.first {
                    ContainerSDKService.imageReferencesMatch($0.reference, image.reference)
                }?.reference ?? image.reference
            } catch {
                if self.isCancellation(error) {
                    self.finishImagePull(reference: trimmed)
                    self.reconcileSelections()
                    self.banner = AppBanner(
                        title: "Image pull cancelled",
                        message: "Stopped downloading \(trimmed). You can pull it again later.",
                        style: .info
                    )
                    return
                }
                throw error
            }
        }
        imagePullTasks[pullKey] = task
    }

    func cancelImagePull(reference: String) {
        let pullKey = imagePullKey(for: reference)
        guard let task = imagePullTasks[pullKey] else { return }
        markImagePullCancelling(reference: reference)
        task.cancel()
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
            self.selectedImageReference = self.displayedImages.first {
                ContainerSDKService.imageReferencesMatch($0.reference, trimmed)
            }?.reference ?? trimmed
        }
    }

    func deleteImage(reference: String) {
        let image = displayedImages.first {
            $0.reference == reference ||
                ContainerSDKService.imageReferencesMatch($0.reference, reference)
        }
        if image?.isBuiltIn == true && image?.isDownloaded != true {
            return
        }
        let deleteDownloadedImage = image?.isDownloaded == true
        let resolvedReference = image?.reference ?? reference
        let activity = deleteDownloadedImage ? "Deleting \(resolvedReference)" : "Removing \(resolvedReference)"

        runMutation(activity: activity) { [service] in
            try await service.deleteImage(reference: resolvedReference, deleteDownloadedImage: deleteDownloadedImage)
            if let selectedImageReference = self.selectedImageReference,
               ContainerSDKService.imageReferencesMatch(selectedImageReference, resolvedReference) {
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
        guard let selectedImage = displayedImages.first(where: {
            $0.isDownloaded && ContainerSDKService.imageReferencesMatch($0.reference, trimmedReference)
        }) else {
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
            draft.imageReference = selectedImage.reference
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

    func imagePullProgress(for reference: String) -> ImagePullProgress? {
        let referenceKey = imagePullKey(for: reference)
        if let progress = imagePulls[referenceKey] {
            return progress
        }

        return imagePulls.first {
            ContainerSDKService.imageReferenceKey($0.key) == referenceKey
        }?.value
    }

    func isSelectedImage(_ image: OCIImageRecord) -> Bool {
        guard let selectedImageReference else { return false }
        return selectedImageReference == image.reference ||
            ContainerSDKService.imageReferencesMatch(selectedImageReference, image.reference)
    }

    @discardableResult
    private func runMutation(
        activity: String,
        operation: @escaping @MainActor @Sendable () async throws -> Void
    ) -> Task<Void, Never> {
        guard !isMutating else {
            return Task {}
        }
        isMutating = true
        activityMessage = activity
        banner = nil

        return Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.isMutating = false
                self.activityMessage = nil
            }

            do {
                try await operation()
            } catch {
                guard !self.isCancellation(error) else { return }
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
        let selectableImages = displayedImages
        if let selectedImageReference, !selectableImages.contains(where: { $0.reference == selectedImageReference }) {
            self.selectedImageReference = selectableImages.first {
                ContainerSDKService.imageReferencesMatch($0.reference, selectedImageReference)
            }?.reference
        }
        if selectedSandboxID == nil {
            selectedSandboxID = sandboxes.first?.id
        }
        if let selectedWorkloadID,
           selectedSandboxDetail?.workloads.contains(where: { $0.id == selectedWorkloadID }) != true {
            self.selectedWorkloadID = nil
        }
        if selectedImageReference == nil {
            selectedImageReference = selectableImages.first?.reference
        }
    }

    private func startImagePull(reference: String) {
        imagePulls[imagePullKey(for: reference)] = ImagePullProgress(reference: reference)
        selectedSidebar = .images
        selectedImageReference = displayedImages.first {
            ContainerSDKService.imageReferencesMatch($0.reference, reference)
        }?.reference ?? reference
    }

    private func updateImagePull(_ progress: ImagePullProgress) {
        let pullKey = imagePullKey(for: progress.reference)
        var progress = progress
        if imagePulls[pullKey]?.isCancelling == true {
            progress.markCancelling()
        }
        imagePulls[pullKey] = progress
        activityMessage = progress.isCancelling
            ? "Cancelling \(progress.reference)"
            : "Pulling \(progress.reference) · \(progress.summary)"
    }

    private func markImagePullCancelling(reference: String) {
        let pullKey = imagePullKey(for: reference)
        var progress = imagePulls[pullKey] ?? ImagePullProgress(reference: reference)
        progress.markCancelling()
        imagePulls[pullKey] = progress
        activityMessage = "Cancelling \(progress.reference)"
    }

    private func finishImagePull(reference: String) {
        let pullKey = imagePullKey(for: reference)
        imagePulls[pullKey] = nil
        imagePullTasks[pullKey] = nil
    }

    private func imagePullKey(for reference: String) -> String {
        ContainerSDKService.imageReferenceKey(reference)
    }

    private func isCancellation(_ error: Error) -> Bool {
        Task.isCancelled || error is CancellationError
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
            if let credentialMessage = Self.registryCredentialFailureMessage(from: description) {
                return credentialMessage
            }
            return description
        }

        let detailed = String(describing: self)
        if let credentialMessage = Self.registryCredentialFailureMessage(from: detailed) {
            return credentialMessage
        }
        let localized = localizedDescription
        if let credentialMessage = Self.registryCredentialFailureMessage(from: localized) {
            return credentialMessage
        }
        if !detailed.isEmpty, detailed != localized {
            return detailed
        }

        let nsError = self as NSError
        if !nsError.domain.isEmpty {
            return "\(localized) (\(nsError.domain) code \(nsError.code))"
        }

        return localized
    }

    private static func registryCredentialFailureMessage(from message: String) -> String? {
        guard let host = ContainerSDKService.registryKeychainFailureHost(fromMessage: message) else {
            return nil
        }

        return "OpenBox hit a registry sign-in lookup failure for \(host). Public images are pulled anonymously; private images need sign-in details in OpenBox."
    }
}
