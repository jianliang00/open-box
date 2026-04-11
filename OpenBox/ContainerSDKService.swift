//
//  ContainerSDKService.swift
//  OpenBox
//
//  Created by Codex on 2026/4/11.
//

import ContainerAPIClient
import ContainerKit
import Foundation

struct SandboxInventory {
    var sandboxes: [SandboxRecord]
    var details: [String: SandboxDetail]
}

enum ContainerSDKServiceError: LocalizedError {
    case emptyReference
    case invalidWorkspacePath(String)
    case commandFailed(code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .emptyReference:
            return "OCI image reference is empty."
        case .invalidWorkspacePath(let path):
            return "Workspace path does not exist or is not a directory: \(path)"
        case .commandFailed(let code, let output):
            return "Command exited with code \(code).\(output.isEmpty ? "" : " \(output)")"
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
    private static let defaultPathEnvironment = "PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin"

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

    func runWorkload(from draft: WorkloadDraft) async throws -> String {
        let kit = Self.makeKit()
        let snapshot = try await kit.getContainer(id: draft.sandboxID)
        let workloadID = Self.makeWorkloadID()
        let process = ProcessConfiguration(
            executable: snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler ? Self.defaultMacOSShellPath : Self.defaultLinuxShellPath,
            arguments: ["-lc", draft.shellCommand],
            environment: [Self.defaultPathEnvironment],
            workingDirectory: draft.workingDirectory,
            terminal: false,
            user: .id(uid: 0, gid: 0)
        )

        if snapshot.configuration.runtimeHandler == Self.macOSRuntimeHandler {
            let configuration = WorkloadConfiguration(
                id: workloadID,
                processConfiguration: process
            )
            try await kit.createWorkload(sandboxID: draft.sandboxID, configuration: configuration)
            try await kit.startWorkload(sandboxID: draft.sandboxID, workloadID: workloadID)
        } else {
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
        return workloadID
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
                    isImageBacked: workload.configuration.isImageBacked
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
