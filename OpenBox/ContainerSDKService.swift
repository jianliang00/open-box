//
//  ContainerSDKService.swift
//  OpenBox
//
//  Created by Codex on 2026/4/11.
//

import ContainerAPIClient
import ContainerKit
import ContainerSandboxServiceClient
import ContainerizationOS
import Foundation

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
        }
    }
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
    private static let linuxRuntimeHandler = "container-runtime-linux"
    private static let macOSRuntimeHandler = "container-runtime-macos"
    private static let managedLabelKey = "com.hellogeek.openbox.managed"
    private static let displayNameLabelKey = "com.hellogeek.openbox.display-name"
    private static let sourceImageLabelKey = "com.hellogeek.openbox.source-image"
    private static let platformLabelKey = "com.hellogeek.openbox.platform"
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
        let kit = Self.makeKit()
        let images = try await kit.listImages()
        return images
            .map {
                OCIImageRecord(
                    reference: $0.reference,
                    digest: $0.digest,
                    mediaType: $0.description.mediaType
                )
            }
            .sorted { lhs, rhs in
                lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
            }
    }

    func loadSandboxes() async throws -> SandboxInventory {
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
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        let detail = await loadSandboxDetail(id: id)
        return SandboxSnapshotRecord(
            record: Self.makeSandboxRecord(from: snapshot, detail: detail),
            detail: detail
        )
    }

    func pullImage(reference: String) async throws -> OCIImageRecord {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ContainerSDKServiceError.emptyReference
        }

        let kit = Self.makeKit()
        let image = try await kit.pullImage(reference: trimmed)
        return OCIImageRecord(
            reference: image.reference,
            digest: image.digest,
            mediaType: image.description.mediaType
        )
    }

    func deleteImage(reference: String) async throws {
        let kit = Self.makeKit()
        try await kit.deleteImage(reference: reference, garbageCollect: true)
    }

    func createSandbox(from draft: SandboxDraft) async throws -> String {
        let kit = Self.makeKit()
        let image = try await ensureImage(reference: draft.imageReference, kit: kit)
        let sandboxID = Self.makeSandboxID(name: draft.name)
        let client = Self.makeClient()
        _ = try await Self.createContainer(id: sandboxID, image: image, draft: draft, client: client)
        if draft.autoStart {
            try await Self.startContainer(id: sandboxID, client: client)
        }
        return sandboxID
    }

    func startSandbox(id: String) async throws {
        let kit = Self.makeKit()
        _ = try await kit.getContainer(id: id)
        try await Self.startContainer(id: id, client: Self.makeClient())
    }

    func stopSandbox(id: String) async throws {
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: id)
        if snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler {
            try await kit.stopSandbox(id: id, options: .default)
        } else {
            try await kit.stopContainer(id: id, options: .default)
        }
    }

    func removeSandbox(id: String) async throws {
        let kit = Self.makeKit()
        try await kit.deleteContainer(id: id, force: true)
    }

    func runWorkload(from draft: WorkloadDraft) async throws -> WorkloadLaunch {
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
                        )
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
            let result = try await kit.execSync(id: draft.sandboxID, configuration: process)
            guard result.exitCode == 0 else {
                let stderr = Self.decode(result.stderr)
                let stdout = Self.decode(result.stdout)
                throw ContainerSDKServiceError.commandFailed(
                    code: result.exitCode,
                    output: stderr.isEmpty ? stdout : stderr
                )
            }
        }
        return WorkloadLaunch(workloadID: workloadID, terminalIO: nil)
    }

    func resizeTerminal(sandboxID: String, workloadID: String, columns: Int, rows: Int) async throws {
        guard columns > 0, rows > 0 else { return }

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
        let kit = Self.makeKit()
        try await kit.stopWorkload(sandboxID: sandboxID, workloadID: workloadID, options: .default)
    }

    func removeWorkload(sandboxID: String, workloadID: String) async throws {
        let kit = Self.makeKit()
        try await kit.removeWorkload(sandboxID: sandboxID, workloadID: workloadID)
    }

    private static func makeKit() -> ContainerKit {
        ContainerKit()
    }

    private static func makeClient() -> ContainerClient {
        ContainerClient()
    }

    private static func startContainer(
        id: String,
        client: ContainerClient
    ) async throws {
        let process = try await client.bootstrap(id: id, stdio: [nil, nil, nil])
        try await process.start()
    }

    private static func shouldUseMacOSIdleProcess(image: Image) async throws -> Bool {
        let index = try await image.index()
        let platforms = index.manifests.compactMap(\.platform)
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

    private func ensureImage(reference: String, kit: ContainerKit) async throws -> Image {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ContainerSDKServiceError.emptyReference
        }

        do {
            return try await kit.getImage(reference: trimmed)
        } catch {
            return try await kit.pullImage(reference: trimmed)
        }
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
        image: Image,
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
                guiEnabled: false,
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
}
