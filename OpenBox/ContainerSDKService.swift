//
//  ContainerSDKService.swift
//  OpenBox
//
//  Created by Codex on 2026/4/11.
//

import ContainerAPIClient
import ContainerKit
import ContainerKitServices
import ContainerSandboxServiceClient
import Containerization
import ContainerizationOCI
import ContainerizationOS
import Foundation
import OSLog

struct SandboxInventory {
    var sandboxes: [SandboxRecord]
    var details: [String: SandboxDetail]
}

struct SandboxSnapshotRecord {
    var record: SandboxRecord
    var detail: SandboxDetail
}

enum ContainerSDKServiceError: LocalizedError {
    case emptyReference
    case invalidWorkspacePath(String)
    case commandFailed(code: Int32, output: String)
    case interactiveShellRequiresMacOSGuest
    case desktopRequiresMacOSGuest
    case desktopGUIIsDisabled
    case bundledContainerRuntimeMissing(String)
    case registryHostUnavailable
    case registryCredentialsIncomplete
    case registrySignInRequired(host: String)
    case registrySignInFailed(host: String)
    case registryCredentialsUnavailable(host: String)

    var errorDescription: String? {
        switch self {
        case .emptyReference:
            return "OCI image reference is empty."
        case .invalidWorkspacePath(let path):
            return "Workspace path does not exist or is not a directory: \(path)"
        case .commandFailed(let code, let output):
            return "Command exited with code \(code).\(output.isEmpty ? "" : " \(output)")"
        case .interactiveShellRequiresMacOSGuest:
            return "Interactive shell workloads are currently supported for macOS sandboxes only."
        case .desktopRequiresMacOSGuest:
            return "Desktop GUI is supported only for macOS guest sandboxes."
        case .desktopGUIIsDisabled:
            return "Desktop GUI is not enabled for this sandbox."
        case .bundledContainerRuntimeMissing(let path):
            return "OpenBox bundled container runtime is missing or incomplete: \(path)"
        case .registryHostUnavailable:
            return "Enter an image reference that includes a registry host before saving sign-in details."
        case .registryCredentialsIncomplete:
            return "Enter the registry username and access token before pulling with sign-in."
        case .registrySignInRequired(let host):
            return "This image requires sign-in to \(host). Pull it again with registry sign-in details in OpenBox."
        case .registrySignInFailed(let host):
            return "Registry sign-in for \(host) was rejected. Check the username and access token, then try again."
        case .registryCredentialsUnavailable(let host):
            return "OpenBox hit a registry sign-in lookup failure for \(host). Public images are pulled anonymously; private images need sign-in details in OpenBox."
        }
    }
}

struct RegistryCredentials: Hashable {
    var host: String
    var username: String
    var token: String
}

enum InteractiveWorkloadInputError: LocalizedError {
    case closed

    var errorDescription: String? {
        switch self {
        case .closed:
            return "The shell input stream is closed."
        }
    }
}

struct WorkloadLaunch {
    let workloadID: String
    let terminalIO: InteractiveWorkloadIO?
    let workload: WorkloadRecord?
}

final class InteractiveWorkloadIO: @unchecked Sendable {
    private static let maxBufferedOutputBytes = 1 << 20

    private let stdinHandle: FileHandle
    private let outputHandle: FileHandle
    private let lock = NSLock()
    private var isClosed = false
    private var bufferedOutput = Data()
    private var outputHandler: (@Sendable (Data) -> Void)?
    private var outputHandlerID: UUID?
    private var sessionObjects: [String: AnyObject] = [:]

    init(stdinHandle: FileHandle, outputHandle: FileHandle) {
        self.stdinHandle = stdinHandle
        self.outputHandle = outputHandle
        outputHandle.readabilityHandler = { [weak self] handle in
            self?.readOutput(from: handle)
        }
    }

    deinit {
        close()
    }

    func send(_ data: Data) throws {
        try lock.withLock {
            guard !isClosed else {
                throw InteractiveWorkloadInputError.closed
            }
            try stdinHandle.write(contentsOf: data)
        }
    }

    func send(_ bytes: ArraySlice<UInt8>) throws {
        try send(Data(bytes))
    }

    func sendLine(_ line: String) throws {
        let text = line.hasSuffix("\n") ? line : "\(line)\n"
        try send(Data(text.utf8))
    }

    @discardableResult
    func setOutputHandler(_ handler: @escaping @Sendable (Data) -> Void) -> UUID? {
        let registration = lock.withLock { () -> (id: UUID, buffered: Data?)? in
            guard !isClosed else { return nil }
            let id = UUID()
            outputHandlerID = id
            outputHandler = handler
            guard !bufferedOutput.isEmpty else { return (id, nil) }
            let data = bufferedOutput
            bufferedOutput.removeAll(keepingCapacity: true)
            return (id, data)
        }
        guard let registration else { return nil }
        if let buffered = registration.buffered {
            handler(buffered)
        }
        return registration.id
    }

    func cachedSessionObject<T: AnyObject>(forKey key: String, create: () -> T) -> T {
        if let existing = lock.withLock({ sessionObjects[key] as? T }) {
            return existing
        }

        let created = create()
        return lock.withLock {
            if let existing = sessionObjects[key] as? T {
                return existing
            }
            sessionObjects[key] = created
            return created
        }
    }

    func clearOutputHandler() {
        lock.withLock {
            outputHandler = nil
            outputHandlerID = nil
        }
    }

    func clearOutputHandler(id: UUID?) {
        lock.withLock {
            guard id == nil || outputHandlerID == id else { return }
            outputHandler = nil
            outputHandlerID = nil
        }
    }

    func close() {
        let shouldClose = lock.withLock { () -> Bool in
            guard !isClosed else { return false }
            isClosed = true
            outputHandler = nil
            outputHandlerID = nil
            sessionObjects.removeAll()
            return true
        }

        guard shouldClose else { return }
        outputHandle.readabilityHandler = nil
        try? stdinHandle.close()
        try? outputHandle.close()
    }

    private func readOutput(from handle: FileHandle) {
        let data = handle.availableData
        guard !data.isEmpty else {
            close()
            return
        }

        let handler = lock.withLock { () -> (@Sendable (Data) -> Void)? in
            guard !isClosed else { return nil }
            guard let outputHandler else {
                bufferOutput(data)
                return nil
            }
            return outputHandler
        }
        handler?(data)
    }

    private func bufferOutput(_ data: Data) {
        let overflow = bufferedOutput.count + data.count - Self.maxBufferedOutputBytes
        if overflow > 0 {
            bufferedOutput.removeFirst(min(overflow, bufferedOutput.count))
        }
        if data.count > Self.maxBufferedOutputBytes {
            bufferedOutput = data.suffix(Self.maxBufferedOutputBytes)
        } else {
            bufferedOutput.append(data)
        }
    }
}

actor ContainerSDKService {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "OpenBox",
        category: "ContainerSDK"
    )

    private static let linuxRuntimeHandler = "container-runtime-linux"
    private static let macOSRuntimeHandler = "container-runtime-macos"
    private static let managedLabelKey = "com.hellogeek.openbox.managed"
    private static let displayNameLabelKey = "com.hellogeek.openbox.display-name"
    private static let sourceImageLabelKey = "com.hellogeek.openbox.source-image"
    private static let platformLabelKey = "com.hellogeek.openbox.platform"
    private static let dockerReferenceTypeAnnotation = "vnd.docker.reference.type"
    private static let attestationManifestReferenceType = "attestation-manifest"
    private static let defaultGuestWorkspacePath = "/Users/Shared/workspace"
    private static let defaultLinuxWorkspacePath = "/workspace"
    private static let defaultMacOSShellPath = "/bin/zsh"
    private static let defaultLinuxShellPath = "/bin/sh"
    private static let defaultPathEntries = [
        "/usr/local/bin",
        "/opt/homebrew/bin",
        "/opt/homebrew/sbin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ]
    private static let terminalLocale = "en_US.UTF-8"
    private static let defaultPathEnvironment = "PATH=\(defaultPathEntries.joined(separator: ":"))"

    private let imageCatalog = ImageCatalogStore()
    private var containerServicesReady = false

    static func makeInteractiveTerminalEnvironment(baseEnvironment: [String], shellPath: String) -> [String] {
        var order: [String] = []
        var values: [String: String] = [:]

        func set(_ key: String, _ value: String) {
            if values[key] == nil {
                order.append(key)
            }
            values[key] = value
        }

        for entry in baseEnvironment {
            guard let separator = entry.firstIndex(of: "=") else { continue }
            let key = String(entry[..<separator])
            guard !key.isEmpty else { continue }
            let value = String(entry[entry.index(after: separator)...])
            set(key, value)
        }

        set("PATH", mergedPath(values["PATH"]))
        set("TERM", "xterm-256color")
        set("COLORTERM", "truecolor")
        if !isUTF8Locale(values["LANG"]) {
            set("LANG", terminalLocale)
        }
        if let lcAll = values["LC_ALL"], !lcAll.isEmpty, !isUTF8Locale(lcAll) {
            set("LC_ALL", terminalLocale)
        }
        if !isUTF8Locale(values["LC_CTYPE"]) {
            set("LC_CTYPE", terminalLocale)
        }
        set("SHELL", shellPath)
        set("TERM_PROGRAM", "OpenBox")

        if values["USER"]?.isEmpty ?? true, let user = inferredUser(fromHome: values["HOME"]) {
            set("USER", user)
        }
        if values["LOGNAME"]?.isEmpty ?? true, let user = values["USER"], !user.isEmpty {
            set("LOGNAME", user)
        }

        return order.compactMap { key in
            guard let value = values[key] else { return nil }
            return "\(key)=\(value)"
        }
    }

    private static func mergedPath(_ currentPath: String?) -> String {
        var entries = (currentPath ?? "")
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init)
        for entry in defaultPathEntries where !entries.contains(entry) {
            entries.append(entry)
        }
        return entries.joined(separator: ":")
    }

    private static func isUTF8Locale(_ locale: String?) -> Bool {
        guard let locale, !locale.isEmpty else { return false }
        return locale.range(of: "UTF-8", options: [.caseInsensitive, .diacriticInsensitive]) != nil
            || locale.range(of: "UTF8", options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    private static func inferredUser(fromHome home: String?) -> String? {
        guard let home, !home.isEmpty else { return nil }
        let components = home.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count >= 2, components[components.count - 2] == "Users" else { return nil }
        return String(components.last!)
    }

    func systemStatus() async throws -> SystemStatus {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let health = try await kit.health()
        return SystemStatus(
            isAvailable: true,
            version: health.apiServerVersion,
            build: health.apiServerBuild,
            appRoot: health.appRoot.path,
            installRoot: health.installRoot.path,
            lastError: nil
        )
    }

    func loadImages() async throws -> [OCIImageRecord] {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let images = try await kit.listImages()
        var records: [OCIImageRecord] = []
        records.reserveCapacity(images.count)

        for image in images {
            records.append(await Self.makeImageRecord(from: image, availability: .downloaded))
        }

        let downloadedReferences = Set(records.map(\.reference))
        for storedImage in try imageCatalog.load() where !downloadedReferences.contains(storedImage.reference) {
            records.append(
                OCIImageRecord(
                    reference: storedImage.reference,
                    digest: "",
                    mediaType: "Not downloaded",
                    availability: .added
                )
            )
        }

        return records.sorted { lhs, rhs in
            lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
        }
    }

    func loadSandboxes() async throws -> SandboxInventory {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let containerSnapshots = try await kit.listContainers()
            .filter { $0.configuration.labels[Self.managedLabelKey] == "true" }
            .sorted { lhs, rhs in
                Self.displayName(for: lhs).localizedCaseInsensitiveCompare(Self.displayName(for: rhs)) == .orderedAscending
            }

        var details: [String: SandboxDetail] = [:]
        for snapshot in containerSnapshots {
            details[snapshot.id] = await loadSandboxDetail(id: snapshot.id)
        }

        let sandboxes = containerSnapshots.map { snapshot in
            Self.makeSandboxRecord(from: snapshot, detail: details[snapshot.id])
        }

        return SandboxInventory(sandboxes: sandboxes, details: details)
    }

    func loadSandbox(id: String) async throws -> SandboxSnapshotRecord {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        let detail = await loadSandboxDetail(id: id)
        return SandboxSnapshotRecord(
            record: Self.makeSandboxRecord(from: snapshot, detail: detail),
            detail: detail
        )
    }

    func pullImage(reference: String, credentials: RegistryCredentials? = nil) async throws -> OCIImageRecord {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ContainerSDKServiceError.emptyReference
        }

        try await ensureContainerServicesReady()

        do {
            let image = try await Self.pullImageFromRegistry(reference: trimmed, credentials: credentials)
            return await Self.makeImageRecord(from: image, availability: .downloaded)
        } catch {
            throw Self.pullImageError(error, reference: trimmed, credentialsWereProvided: credentials != nil)
        }
    }

    func addImageReference(reference: String) async throws {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ContainerSDKServiceError.emptyReference
        }

        try imageCatalog.add(reference: trimmed)
    }

    func deleteImage(reference: String, deleteDownloadedImage: Bool) async throws {
        if deleteDownloadedImage {
            try await ensureContainerServicesReady()
            let kit = Self.makeKit()
            try await kit.deleteImage(reference: reference, garbageCollect: true)
        }
        try imageCatalog.remove(reference: reference)
    }

    func createSandbox(from draft: SandboxDraft) async throws -> String {
        try await ensureContainerServicesReady()
        try await Self.normalizeRuntimeImageReferenceIfNeeded(reference: draft.imageReference)
        let kit = Self.makeKit()
        let image = try await kit.getImage(reference: draft.imageReference)
        let sandboxID = Self.makeSandboxID(name: draft.name)
        let client = Self.makeClient()
        let configuration = try await Self.createContainer(id: sandboxID, image: image, draft: draft, client: client)
        if draft.autoStart {
            if configuration.runtimeHandler == Self.macOSRuntimeHandler {
                Self.logger.info("Auto-starting macOS sandbox without Desktop GUI: id=\(sandboxID, privacy: .public)")
                try await Self.startContainer(id: sandboxID, client: client, presentGUI: false)
            } else {
                Self.logger.info("Auto-starting non-macOS sandbox: id=\(sandboxID, privacy: .public) runtime=\(configuration.runtimeHandler, privacy: .public)")
                try await Self.startContainer(id: sandboxID, client: client)
            }
        }
        return sandboxID
    }

    func startSandbox(id: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        if snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler {
            Self.logger.info("Starting macOS sandbox without Desktop GUI: id=\(id, privacy: .public)")
            try await Self.startContainer(id: id, client: Self.makeClient(), presentGUI: false)
        } else {
            Self.logger.info("Starting non-macOS sandbox: id=\(id, privacy: .public) runtime=\(snapshot.configuration.runtimeHandler, privacy: .public)")
            try await Self.startContainer(id: id, client: Self.makeClient())
        }
    }

    func launchDesktop(id: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        guard snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler else {
            throw ContainerSDKServiceError.desktopRequiresMacOSGuest
        }
        guard snapshot.configuration.macosGuest?.guiEnabled == true else {
            throw ContainerSDKServiceError.desktopGUIIsDisabled
        }

        if SandboxStatus(runtimeRawValue: snapshot.status.rawValue) == .running {
            Self.logger.info("Showing Desktop GUI for running sandbox: id=\(id, privacy: .public)")
            try await kit.showSandboxGUI(id: id)
        } else {
            Self.logger.info("Starting macOS sandbox with Desktop GUI: id=\(id, privacy: .public)")
            try await Self.startContainer(id: id, client: Self.makeClient(), presentGUI: true)
        }
    }

    func stopSandbox(id: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        if snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler {
            try await kit.stopSandbox(id: id, options: .default)
        } else {
            try await kit.stopContainer(id: id, options: .default)
        }
    }

    func removeSandbox(id: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        try await kit.deleteContainer(id: id, force: true)
    }

    func runWorkload(from draft: WorkloadDraft) async throws -> WorkloadLaunch {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: draft.sandboxID)
        let isMacOSGuest = snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler
        let environment = draft.mode == .interactiveShell
            ? Self.makeInteractiveTerminalEnvironment(
                baseEnvironment: snapshot.configuration.initProcess.environment,
                shellPath: draft.shellPath
            )
            : [Self.defaultPathEnvironment]
        let processUser: ProcessConfiguration.User = draft.mode == .interactiveShell
            ? snapshot.configuration.initProcess.user
            : .id(uid: 0, gid: 0)
        let workloadID = Self.makeWorkloadID()
        let process = ProcessConfiguration(
            executable: draft.mode == .interactiveShell
                ? draft.shellPath
                : (isMacOSGuest ? Self.defaultMacOSShellPath : Self.defaultLinuxShellPath),
            arguments: draft.mode == .interactiveShell ? ["-i"] : ["-lc", draft.shellCommand],
            environment: environment,
            workingDirectory: draft.workingDirectory,
            terminal: draft.mode == .interactiveShell,
            user: processUser
        )

        if isMacOSGuest {
            let configuration = WorkloadConfiguration(
                id: workloadID,
                processConfiguration: process
            )

            if draft.mode == .interactiveShell {
                let stdinPipe = Pipe()
                let outputPipe = Pipe()
                do {
                    let client = Self.makeClient()
                    try await client.createWorkload(
                        containerId: draft.sandboxID,
                        configuration: configuration,
                        stdio: [
                            stdinPipe.fileHandleForReading,
                            outputPipe.fileHandleForWriting,
                            nil
                        ]
                    )
                    try await client.startWorkload(containerId: draft.sandboxID, workloadId: workloadID)
                    try? stdinPipe.fileHandleForReading.close()
                    try? outputPipe.fileHandleForWriting.close()
                    return WorkloadLaunch(
                        workloadID: workloadID,
                        terminalIO: InteractiveWorkloadIO(
                            stdinHandle: stdinPipe.fileHandleForWriting,
                            outputHandle: outputPipe.fileHandleForReading
                        ),
                        workload: nil
                    )
                } catch {
                    try? stdinPipe.fileHandleForReading.close()
                    try? stdinPipe.fileHandleForWriting.close()
                    try? outputPipe.fileHandleForReading.close()
                    try? outputPipe.fileHandleForWriting.close()
                    throw error
                }
            }

            try await kit.createWorkload(sandboxID: draft.sandboxID, configuration: configuration)
            try await kit.startWorkload(sandboxID: draft.sandboxID, workloadID: workloadID)
        } else {
            guard draft.mode == .command else {
                throw ContainerSDKServiceError.interactiveShellRequiresMacOSGuest
            }
            let startedAt = Date()
            let result = try await kit.execSync(id: draft.sandboxID, configuration: process)
            let exitedAt = Date()
            let stdoutLogPath = try Self.writeTransientWorkloadLog(
                sandboxID: draft.sandboxID,
                workloadID: workloadID,
                stream: "stdout",
                data: result.stdout
            )
            let stderrLogPath = try Self.writeTransientWorkloadLog(
                sandboxID: draft.sandboxID,
                workloadID: workloadID,
                stream: "stderr",
                data: result.stderr
            )
            return WorkloadLaunch(
                workloadID: workloadID,
                terminalIO: nil,
                workload: WorkloadRecord(
                    id: workloadID,
                    command: Self.describe(process: process),
                    workingDirectory: draft.workingDirectory,
                    status: .stopped,
                    exitCode: result.exitCode,
                    stdoutLogPath: stdoutLogPath,
                    stderrLogPath: stderrLogPath,
                    startedAt: startedAt,
                    exitedAt: exitedAt,
                    isImageBacked: false,
                    isTerminal: false
                )
            )
        }
        return WorkloadLaunch(workloadID: workloadID, terminalIO: nil, workload: nil)
    }

    func resizeTerminal(sandboxID: String, workloadID: String, columns: Int, rows: Int) async throws {
        guard columns > 0, rows > 0 else { return }

        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: sandboxID)
        let client = try await SandboxClient.create(id: sandboxID, runtime: snapshot.configuration.runtimeHandler)
        try await client.resize(
            workloadID,
            size: Terminal.Size(
                width: UInt16(clamping: columns),
                height: UInt16(clamping: rows)
            )
        )
    }

    func stopWorkload(sandboxID: String, workloadID: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        try await kit.stopWorkload(sandboxID: sandboxID, workloadID: workloadID, options: .default)
    }

    func removeWorkload(sandboxID: String, workloadID: String) async throws {
        try await ensureContainerServicesReady()
        let kit = Self.makeKit()
        try await kit.removeWorkload(sandboxID: sandboxID, workloadID: workloadID)
    }

    private func ensureContainerServicesReady() async throws {
        let services = try Self.makeBundledContainerServices()
        if containerServicesReady, await Self.isBundledServiceRunning(services: services) {
            return
        }

        containerServicesReady = false
        Self.logger.info(
            "Ensuring bundled container services: installRoot=\(services.installRootURL.path, privacy: .public)"
        )
        try await services.ensureRunning(timeout: .seconds(30))

        let health = try await Self.makeKit().health(timeout: .seconds(5))
        guard services.owns(health) else {
            throw Self.unexpectedContainerServiceError(health: health, services: services)
        }

        containerServicesReady = true
    }

    private static func isBundledServiceRunning(services: ContainerKitServices) async -> Bool {
        guard let health = try? await makeKit().health(timeout: .seconds(2)) else {
            return false
        }
        return services.owns(health)
    }

    private static func makeBundledContainerServices() throws -> ContainerKitServices {
        let installRoot = try bundledContainerInstallRoot()
        return ContainerKitServices(
            appRoot: try bundledContainerAppRoot(),
            installation: ContainerInstallation(
                installRoot: installRoot,
                apiServerExecutableURL: installRoot.appendingPathComponent("bin/container-apiserver")
            )
        )
    }

    private static func bundledContainerInstallRoot() throws -> URL {
        guard let resourceURL = Foundation.Bundle.main.resourceURL else {
            throw ContainerSDKServiceError.bundledContainerRuntimeMissing("Bundle resources")
        }

        let installRoot = resourceURL.appendingPathComponent("container", isDirectory: true)
        let apiServerURL = installRoot.appendingPathComponent("bin/container-apiserver")
        guard FileManager.default.isExecutableFile(atPath: apiServerURL.path) else {
            throw ContainerSDKServiceError.bundledContainerRuntimeMissing(apiServerURL.path)
        }
        return installRoot
    }

    private static func bundledContainerAppRoot() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleID = Foundation.Bundle.main.bundleIdentifier ?? "OpenBox"
        return applicationSupport
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("container", isDirectory: true)
    }

    private static func unexpectedContainerServiceError(
        health: SystemHealth,
        services: ContainerKitServices
    ) -> NSError {
        NSError(
            domain: "OpenBox.ContainerSDKService",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: """
                OpenBox connected to a container service that is not owned by this app bundle.
                expected appRoot: \(services.appRootURL.path)
                actual appRoot: \(health.appRoot.path)
                expected installRoot: \(services.installRootURL.path)
                actual installRoot: \(health.installRoot.path)
                """
            ]
        )
    }

    private static func makeKit() -> ContainerKit {
        ContainerKit()
    }

    private static func makeClient() -> ContainerClient {
        ContainerClient()
    }

    private static func startContainer(
        id: String,
        client: ContainerClient,
        presentGUI: Bool = true
    ) async throws {
        Self.logger.info("Bootstrapping container: id=\(id, privacy: .public) presentGUI=\(presentGUI, privacy: .public)")
        let process = try await client.bootstrap(id: id, stdio: [nil, nil, nil], presentGUI: presentGUI)
        try await process.start()
    }

    private static func shouldUseMacOSIdleProcess(image: ClientImage) async throws -> Bool {
        let platforms = try await runtimePlatforms(for: image)
        let hasLinuxForHost = platforms.contains { platform in
            platform.os == "linux" && platform.architecture == Self.hostOCIArchitecture()
        }
        let hasDarwinArm64 = platforms.contains { platform in
            platform.os == "darwin" && platform.architecture == "arm64"
        }
        let operatingSystems = Set(platforms.map(\.os))

        if !hasLinuxForHost, !hasDarwinArm64 {
            let linuxPlatform = Parser.platform(os: "linux", arch: Self.hostOCIArchitecture())
            if (try? await image.config(for: linuxPlatform)) != nil {
                return false
            }

            let darwinPlatform = Parser.platform(os: "darwin", arch: "arm64")
            if (try? await image.config(for: darwinPlatform)) != nil {
                return true
            }
        }

        return hasDarwinArm64 && !hasLinuxForHost && !operatingSystems.contains("linux")
    }

    private static func runtimePlatforms(in index: Index) -> [Platform] {
        var seen = Set<Platform>()
        var platforms: [Platform] = []

        for descriptor in index.manifests {
            guard !isAttestationManifest(descriptor),
                  let platform = descriptor.platform,
                  seen.insert(platform).inserted else {
                continue
            }
            platforms.append(platform)
        }

        return platforms
    }

    private static func runtimePlatforms(for image: ClientImage) async throws -> [Platform] {
        let contentStore = try localContentStore()
        return await runtimePlatforms(from: image.descriptor, contentStore: contentStore)
    }

    private static func runtimePlatforms<C: ContentStore>(in index: Index, contentStore: C) async -> [Platform] {
        var seen = Set<Platform>()
        var platforms: [Platform] = []

        for descriptor in index.manifests {
            let descriptorPlatforms = await runtimePlatforms(from: descriptor, contentStore: contentStore)
            for platform in descriptorPlatforms where seen.insert(platform).inserted {
                platforms.append(platform)
            }
        }

        return platforms
    }

    private static func runtimePlatforms<C: ContentStore>(from descriptor: Descriptor, contentStore: C) async -> [Platform] {
        guard !isAttestationManifest(descriptor) else { return [] }

        if let platform = descriptor.platform {
            return [platform]
        }

        if isImageIndexMediaType(descriptor.mediaType) {
            let nestedIndex: Index?
            do {
                nestedIndex = try await contentStore.get(digest: descriptor.digest)
            } catch {
                return []
            }
            guard let nestedIndex else { return [] }
            return await runtimePlatforms(in: nestedIndex, contentStore: contentStore)
        }

        guard isImageManifestMediaType(descriptor.mediaType) else { return [] }

        let manifest: Manifest?
        do {
            manifest = try await contentStore.get(digest: descriptor.digest)
        } catch {
            return []
        }
        guard let manifest else { return [] }

        let config: ContainerizationOCI.Image?
        do {
            config = try await contentStore.get(digest: manifest.config.digest)
        } catch {
            return []
        }
        guard let config else { return [] }

        return [
            Platform(
                arch: config.architecture,
                os: config.os,
                osVersion: config.osVersion,
                osFeatures: config.osFeatures,
                variant: config.variant
            )
        ]
    }

    static func runtimePlatformDescriptions(in index: Index) -> [String] {
        runtimePlatforms(in: index)
            .map(\.description)
            .sorted()
    }

    static func runtimePlatformDescriptions<C: ContentStore>(
        from descriptor: Descriptor,
        contentStore: C
    ) async -> [String] {
        let platforms = await runtimePlatforms(from: descriptor, contentStore: contentStore)
        return Array(Set(platforms.map(\.description))).sorted()
    }

    static func runtimeImageDescriptor<C: ContentStore>(
        from descriptor: Descriptor,
        contentStore: C
    ) async -> Descriptor {
        var current = descriptor
        var visited = Set<String>()

        while isImageIndexMediaType(current.mediaType), visited.insert(current.digest).inserted {
            let index: Index?
            do {
                index = try await contentStore.get(digest: current.digest)
            } catch {
                return current
            }

            let runtimeDescriptors = index?.manifests.filter { !isAttestationManifest($0) } ?? []
            guard runtimeDescriptors.count == 1,
                  let nested = runtimeDescriptors.first,
                  isImageIndexMediaType(nested.mediaType) else {
                return current
            }

            current = nested
        }

        return current
    }

    private static func isAttestationManifest(_ descriptor: Descriptor) -> Bool {
        descriptor.annotations?[dockerReferenceTypeAnnotation] == attestationManifestReferenceType
    }

    private static func isImageIndexMediaType(_ mediaType: String) -> Bool {
        mediaType == MediaTypes.index || mediaType == MediaTypes.dockerManifestList
    }

    private static func isImageManifestMediaType(_ mediaType: String) -> Bool {
        mediaType == MediaTypes.imageManifest || mediaType == MediaTypes.dockerManifest
    }

    private static func localContentStore() throws -> LocalContentStore {
        try LocalContentStore(
            path: bundledContainerAppRoot().appendingPathComponent("content", isDirectory: true)
        )
    }

    private static func hostOCIArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let architecture = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        return architecture == "x86_64" ? "amd64" : architecture
    }

    private static func mountSpecifications(
        for workspacePath: String,
        draft: SandboxDraft,
        useMacOSGuest: Bool
    ) -> [String] {
        guard !workspacePath.isEmpty else { return [] }

        let destination = useMacOSGuest ? Self.defaultGuestWorkspacePath : Self.defaultLinuxWorkspacePath
        var specification = "type=bind,source=\(workspacePath),target=\(destination)"
        if draft.shareMode == .readOnly {
            specification += ",readonly"
        }
        return [specification]
    }

    private static func decode(_ data: Data) -> String {
        String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func writeTransientWorkloadLog(
        sandboxID: String,
        workloadID: String,
        stream: String,
        data: Data
    ) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("openbox-workload-logs", isDirectory: true)
            .appendingPathComponent(safeFileComponent(sandboxID), isDirectory: true)
            .appendingPathComponent(safeFileComponent(workloadID), isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = directory.appendingPathComponent("\(safeFileComponent(stream)).log")
        try data.write(to: url, options: .atomic)
        return url.path
    }

    private static func safeFileComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" })
    }

    private func loadSandboxDetail(id: String) async -> SandboxDetail {
        do {
            let kit = Self.makeKit()
            let container = try await kit.getContainer(id: id)
            guard container.configuration.runtimeHandler == Self.macOSRuntimeHandler else {
                return Self.makeSandboxDetail(id: id, snapshot: container)
            }

            let snapshot = try await kit.inspectSandbox(id: id)
            let logPaths = try? await kit.sandboxLogPaths(id: id)
            return Self.makeSandboxDetail(id: id, snapshot: snapshot, logPaths: logPaths)
        } catch {
            return SandboxDetail(
                sandboxID: id,
                networks: [],
                workloads: [],
                logPaths: nil,
                lastError: error.openBoxMessage
            )
        }
    }

    static func normalizedIdentifierBase(_ value: String) -> String {
        let lowered = value.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        let mappedScalars = lowered.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(mappedScalars)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-._"))
        return collapsed.isEmpty ? "sandbox" : String(collapsed.prefix(40))
    }

    static func makeSandboxID(name: String) -> String {
        let prefix = normalizedIdentifierBase(name)
        let suffix = UUID().uuidString
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .prefix(8)
        let combined = "openbox-\(prefix)-\(suffix)"
        return String(combined.prefix(63)).trimmingCharacters(in: CharacterSet(charactersIn: "-._"))
    }

    static func makeWorkloadID() -> String {
        "cmd-\(UUID().uuidString.lowercased())"
    }

    private static func createContainer(
        id: String,
        image: ClientImage,
        draft: SandboxDraft,
        client: ContainerClient
    ) async throws -> ContainerConfiguration {
        let trimmedWorkspace = draft.workspacePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWorkspace.isEmpty {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: trimmedWorkspace, isDirectory: &isDirectory), isDirectory.boolValue else {
                throw ContainerSDKServiceError.invalidWorkspacePath(trimmedWorkspace)
            }
        }

        let useMacOSIdleProcess = try await Self.shouldUseMacOSIdleProcess(image: image)
        let processFlags = try Flags.Process.parse([
            "--env", Self.defaultPathEnvironment
        ])

        var managementArguments = [
            "--entrypoint", useMacOSIdleProcess ? "/usr/bin/tail" : Self.defaultLinuxShellPath,
            "--os", useMacOSIdleProcess ? "darwin" : "linux",
            "--arch", useMacOSIdleProcess ? "arm64" : Self.hostOCIArchitecture()
        ]
        Self.mountSpecifications(for: trimmedWorkspace, draft: draft, useMacOSGuest: useMacOSIdleProcess)
            .forEach { mount in
                managementArguments.append(contentsOf: ["--mount", mount])
            }
        let managementFlags = try Flags.Management.parse(managementArguments)

        let resourceFlags = try Flags.Resource.parse([
            "--cpus", "\(draft.cpuCores)",
            "--memory", "\(draft.memoryGB)G"
        ])

        let imageFetchFlags = try Flags.ImageFetch.parse([
            "--max-concurrent-downloads", "3"
        ])
        let registryFlags = try Flags.Registry.parse([])

        let resolved = try await Utility.containerConfigFromFlags(
            id: id,
            image: image.reference,
            arguments: useMacOSIdleProcess ? ["-f", "/dev/null"] : ["-lc", "sleep infinity"],
            process: processFlags,
            management: managementFlags,
            resource: resourceFlags,
            registry: registryFlags,
            imageFetch: imageFetchFlags,
            progressUpdate: { _ in },
            log: .init(label: "OpenBox.ContainerSDKService")
        )

        var configuration = resolved.0

        configuration.resources.cpus = draft.cpuCores
        configuration.resources.memoryInBytes = UInt64(draft.memoryGB) * 1024 * 1024 * 1024
        configuration.resources.storage = UInt64(draft.diskGB) * 1024 * 1024 * 1024
        configuration.labels[Self.managedLabelKey] = "true"
        configuration.labels[Self.displayNameLabelKey] = draft.name
        configuration.labels[Self.sourceImageLabelKey] = image.reference
        configuration.labels[Self.platformLabelKey] = configuration.platform.description

        if configuration.runtimeHandler == Self.macOSRuntimeHandler {
            configuration.macosGuest = .init(
                snapshotEnabled: false,
                guiEnabled: draft.desktopGUIEnabled,
                agentPort: 27_000,
                networkBackend: .virtualizationNAT
            )
        }

        try await client.create(configuration: configuration, options: .default, kernel: resolved.1, initImage: resolved.2)
        return configuration
    }

    private static func displayName(for snapshot: ContainerSnapshot) -> String {
        snapshot.configuration.labels[Self.displayNameLabelKey] ?? snapshot.id
    }

    private static func makeSandboxRecord(
        from snapshot: ContainerSnapshot,
        detail: SandboxDetail?
    ) -> SandboxRecord {
        let workspaceMount = snapshot.configuration.mounts.first(where: \.isVirtiofs)
        let shareMode = workspaceMount.map { $0.options.readonly ? FileShareMode.readOnly : .readWrite }
        let memoryGB = max(1, Int(snapshot.configuration.resources.memoryInBytes / 1024 / 1024 / 1024))
        let diskGB = snapshot.configuration.resources.storage.map { Int($0 / 1024 / 1024 / 1024) }
        return SandboxRecord(
            id: snapshot.id,
            name: displayName(for: snapshot),
            imageReference: snapshot.configuration.image.reference,
            imageDigest: snapshot.configuration.image.digest,
            runtimeHandler: snapshot.configuration.runtimeHandler,
            platform: snapshot.configuration.platform.description,
            desktopGUIEnabled: snapshot.configuration.macosGuest?.guiEnabled == true,
            status: SandboxStatus(runtimeRawValue: snapshot.status.rawValue),
            cpuCores: snapshot.configuration.resources.cpus,
            memoryGB: memoryGB,
            diskGB: diskGB,
            workspacePath: workspaceMount?.source,
            shareMode: shareMode,
            startedAt: snapshot.startedDate,
            workloadCount: detail?.workloads.count ?? 0,
            lastError: detail?.lastError,
            labels: snapshot.configuration.labels
        )
    }

    private static func makeSandboxDetail(
        id: String,
        snapshot: ContainerSnapshot
    ) -> SandboxDetail {
        let networks = snapshot.networks.map { attachment in
            SandboxNetworkRecord(
                id: "\(attachment.network)-\(attachment.hostname)",
                networkID: attachment.network,
                hostname: attachment.hostname,
                ipv4Address: String(describing: attachment.ipv4Address),
                gateway: String(describing: attachment.ipv4Gateway),
                dnsServers: attachment.dns?.nameservers ?? []
            )
        }

        return SandboxDetail(
            sandboxID: id,
            networks: networks,
            workloads: [],
            logPaths: nil,
            lastError: nil
        )
    }

    private static func makeSandboxDetail(
        id: String,
        snapshot: SandboxSnapshot,
        logPaths: SandboxLogPaths?
    ) -> SandboxDetail {
        let networks = snapshot.networks.map { attachment in
            SandboxNetworkRecord(
                id: "\(attachment.network)-\(attachment.hostname)",
                networkID: attachment.network,
                hostname: attachment.hostname,
                ipv4Address: String(describing: attachment.ipv4Address),
                gateway: String(describing: attachment.ipv4Gateway),
                dnsServers: attachment.dns?.nameservers ?? []
            )
        }

        let workloads = snapshot.workloads
            .map { workload in
                WorkloadRecord(
                    id: workload.id,
                    command: describe(process: workload.configuration.processConfiguration),
                    workingDirectory: workload.configuration.processConfiguration.workingDirectory,
                    status: WorkloadStatus(runtimeRawValue: workload.status.rawValue),
                    exitCode: workload.exitCode,
                    stdoutLogPath: workload.stdoutLogPath,
                    stderrLogPath: workload.stderrLogPath,
                    startedAt: workload.startedDate,
                    exitedAt: workload.exitedAt,
                    isImageBacked: workload.configuration.isImageBacked,
                    isTerminal: workload.configuration.processConfiguration.terminal
                )
            }
            .sorted { lhs, rhs in
                lhs.startedAt ?? .distantPast > rhs.startedAt ?? .distantPast
            }

        let logRecord = logPaths.map {
            SandboxLogRecord(
                eventLogPath: $0.eventLogPath,
                bootLogPath: $0.bootLogPath,
                guestAgentLogPath: $0.guestAgentLogPath,
                guestAgentStderrLogPath: $0.guestAgentStderrLogPath
            )
        }

        return SandboxDetail(
            sandboxID: id,
            networks: networks,
            workloads: workloads,
            logPaths: logRecord,
            lastError: nil
        )
    }

    private static func describe(process: ProcessConfiguration) -> String {
        ([process.executable] + process.arguments).joined(separator: " ")
    }

    static func registryHost(forImageReference reference: String) -> String? {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = (try? ClientImage.normalizeReference(trimmed)) ?? trimmed
        guard let separator = normalized.firstIndex(of: "/") else { return nil }

        let host = String(normalized[..<separator])
        return host.contains(".") || host.contains(":") || host == "localhost" ? host : nil
    }

    static func registryKeychainFailureHost(fromMessage message: String) -> String? {
        guard message.contains("error querying keychain"),
              message.contains("status: -25293") else {
            return nil
        }

        return host(after: "error querying keychain for ", in: message)
    }

    private static func pullImageFromRegistry(
        reference: String,
        credentials: RegistryCredentials?
    ) async throws -> Containerization.Image {
        let normalizedReference = try ClientImage.normalizeReference(reference)
        let authentication = try registryAuthentication(for: credentials)
        let imageStore = try Containerization.ImageStore(path: bundledContainerAppRoot())
        let image = try await imageStore.pull(
            reference: normalizedReference,
            insecure: shouldUseInsecureRegistryTransport(for: normalizedReference),
            auth: authentication,
            maxConcurrentDownloads: 3
        )
        return try await normalizeRuntimeImageIfNeeded(image, in: imageStore)
    }

    @discardableResult
    private static func normalizeRuntimeImageReferenceIfNeeded(reference: String) async throws -> Containerization.Image {
        let imageStore = try Containerization.ImageStore(path: bundledContainerAppRoot())
        let image = try await imageStore.get(reference: reference)
        return try await normalizeRuntimeImageIfNeeded(image, in: imageStore)
    }

    private static func normalizeRuntimeImageIfNeeded(
        _ image: Containerization.Image,
        in imageStore: Containerization.ImageStore
    ) async throws -> Containerization.Image {
        let contentStore = try localContentStore()
        let descriptor = await runtimeImageDescriptor(from: image.descriptor, contentStore: contentStore)
        guard descriptor.digest != image.descriptor.digest || descriptor.mediaType != image.descriptor.mediaType else {
            return image
        }

        return try await imageStore.create(
            description: Containerization.Image.Description(
                reference: image.reference,
                descriptor: descriptor
            )
        )
    }

    private static func registryAuthentication(for credentials: RegistryCredentials?) throws -> BasicAuthentication? {
        guard let credentials else {
            return nil
        }

        let host = credentials.host.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = credentials.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = credentials.token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else {
            throw ContainerSDKServiceError.registryHostUnavailable
        }
        guard !username.isEmpty, !token.isEmpty else {
            throw ContainerSDKServiceError.registryCredentialsIncomplete
        }

        return BasicAuthentication(username: username, password: token)
    }

    private static func shouldUseInsecureRegistryTransport(for reference: String) -> Bool {
        guard let host = registryHost(forImageReference: reference)?.lowercased() else {
            return false
        }

        return host == "localhost" ||
            host.hasPrefix("localhost:") ||
            host.hasPrefix("127.") ||
            host.hasPrefix("10.") ||
            host.hasPrefix("192.168.") ||
            host.range(of: #"^172\.(1[6-9]|2[0-9]|3[0-1])\."#, options: .regularExpression) != nil ||
            host.hasSuffix(".local") ||
            host.hasSuffix(".test")
    }

    private static func pullImageError(
        _ error: Error,
        reference: String,
        credentialsWereProvided: Bool
    ) -> Error {
        if let host = registryKeychainFailureHost(from: error) {
            return ContainerSDKServiceError.registryCredentialsUnavailable(host: host)
        }

        if isRegistryAuthenticationError(error) {
            let host = registryHost(forImageReference: reference) ?? "the registry"
            return credentialsWereProvided
                ? ContainerSDKServiceError.registrySignInFailed(host: host)
                : ContainerSDKServiceError.registrySignInRequired(host: host)
        }

        return error
    }

    private static func registryKeychainFailureHost(from error: Error) -> String? {
        let detailed = String(describing: error)
        if let host = registryKeychainFailureHost(fromMessage: detailed) {
            return host
        }

        let localized = error.localizedDescription
        return registryKeychainFailureHost(fromMessage: localized)
    }

    private static func isRegistryAuthenticationError(_ error: Error) -> Bool {
        let message = "\(String(describing: error)) \(error.localizedDescription)".lowercased()
        return message.contains("no credentials found for host") ||
            message.contains("unauthorized") ||
            message.contains("forbidden") ||
            message.contains("status: 401") ||
            message.contains("status: 403")
    }

    private static func host(after marker: String, in message: String) -> String? {
        guard let range = message.range(of: marker) else {
            return nil
        }

        let tail = message[range.upperBound...]
        let end = tail.firstIndex {
            $0.isWhitespace || $0 == ")" || $0 == "\"" || $0 == "'" || $0 == ","
        } ?? tail.endIndex
        let host = String(tail[..<end])
        return host.isEmpty ? nil : host
    }

    private static func makeImageRecord(from image: ClientImage, availability: OCIImageAvailability) async -> OCIImageRecord {
        OCIImageRecord(
            reference: image.reference,
            digest: image.digest,
            mediaType: image.description.mediaType,
            availability: availability,
            platforms: await imagePlatforms(for: image)
        )
    }

    private static func imagePlatforms(for image: ClientImage) async -> [String] {
        guard let contentStore = try? localContentStore() else { return [] }
        return await runtimePlatformDescriptions(from: image.descriptor, contentStore: contentStore)
    }

    private static func makeImageRecord(from image: Containerization.Image, availability: OCIImageAvailability) async -> OCIImageRecord {
        OCIImageRecord(
            reference: image.reference,
            digest: image.digest,
            mediaType: image.mediaType,
            availability: availability,
            platforms: await imagePlatforms(for: image)
        )
    }

    private static func imagePlatforms(for image: Containerization.Image) async -> [String] {
        guard let contentStore = try? localContentStore() else { return [] }
        return await runtimePlatformDescriptions(from: image.descriptor, contentStore: contentStore)
    }
}

private struct StoredImageCatalog: Codable {
    var images: [StoredImageReference] = []
}

private struct StoredImageReference: Codable, Hashable {
    var reference: String
    var addedAt: Date
}

private final class ImageCatalogStore {
    private let fileManager: FileManager
    private let url: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("OpenBox", isDirectory: true)
            ?? fileManager.temporaryDirectory.appendingPathComponent("OpenBox", isDirectory: true)
        self.url = baseURL.appendingPathComponent("image-catalog.json")
    }

    func load() throws -> [StoredImageReference] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(StoredImageCatalog.self, from: data)
        return catalog.images
    }

    func add(reference: String) throws {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ContainerSDKServiceError.emptyReference
        }

        var images = try load()
        guard !images.contains(where: { $0.reference == trimmed }) else { return }
        images.append(StoredImageReference(reference: trimmed, addedAt: Date()))
        try save(images)
    }

    func remove(reference: String) throws {
        let images = try load().filter { $0.reference != reference }
        try save(images)
    }

    private func save(_ images: [StoredImageReference]) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var catalog = StoredImageCatalog()
        catalog.images = images.sorted {
            $0.reference.localizedCaseInsensitiveCompare($1.reference) == .orderedAscending
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(catalog)
        try data.write(to: url, options: .atomic)
    }
}
