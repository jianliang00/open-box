//
//  OpenBoxTests.swift
//  OpenBoxTests
//
//  Created by jianliang on 2026/1/24.
//

import AppKit
import ContainerizationOCI
import Foundation
import SwiftTerm
import Testing
@testable import OpenBox

private final class LockedData: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ newData: Data) {
        lock.withLock {
            data.append(newData)
        }
    }

    var value: Data {
        lock.withLock {
            data
        }
    }
}

private struct LocalizedTestError: LocalizedError {
    let errorDescription: String?
}

private func writeContent<T: Encodable>(
    _ content: T,
    mediaType: String,
    to contentStore: LocalContentStore
) async throws -> Descriptor {
    let (id, directory) = try await contentStore.newIngestSession()
    do {
        let writer = try ContentWriter(for: directory)
        let result = try writer.create(from: content)
        _ = try await contentStore.completeIngestSession(id)
        return Descriptor(
            mediaType: mediaType,
            digest: result.digest.digestString,
            size: result.size
        )
    } catch {
        try? await contentStore.cancelIngestSession(id)
        throw error
    }
}

struct OpenBoxTests {

    @Test func normalizedIdentifierBaseCollapsesUnsupportedCharacters() async throws {
        #expect(
            ContainerSDKService.normalizedIdentifierBase("My Sandbox 🚀 / Beta")
                == "my-sandbox-beta"
        )
    }

    @Test func generatedSandboxIDMatchesContainerSyntax() async throws {
        let identifier = ContainerSDKService.makeSandboxID(name: "Sandbox For QA")
        #expect(identifier.hasPrefix("openbox-sandbox-for-qa-"))
        #expect(identifier.count <= 63)
        #expect(
            identifier.range(
                of: #"^[a-z0-9](?:[a-z0-9._-]{0,61}[a-z0-9])?$"#,
                options: .regularExpression
            ) != nil
        )
    }

    @Test func macOSRuntimeLaunchdLabelMatchesContainerRuntimePluginLabel() {
        #expect(
            ContainerSDKService.macOSRuntimeServiceLabel(id: "sandbox-1")
                == "com.apple.container.container-runtime-macos.sandbox-1"
        )
        #expect(
            ContainerSDKService.macOSRuntimeLaunchdLabel(id: "sandbox-1", domain: "gui/501")
                == "gui/501/com.apple.container.container-runtime-macos.sandbox-1"
        )
    }

    @Test func macOSSidecarLaunchdLabelMatchesRuntimeSidecarLabel() {
        #expect(
            ContainerSDKService.macOSSidecarLaunchdLabel(id: "sandbox-1", uid: 501)
                == "gui/501/com.apple.container.runtime.container-runtime-macos-sidecar.sandbox-1"
        )
    }

    @Test func keychainRegistryErrorMessageSuggestsCredentialRepair() {
        let error = LocalizedTestError(
            errorDescription: #"internalError: "error querying keychain for ghcr.io (cause:"queryError("query failure: unhandledError(status: -25293)")")""#
        )

        #expect(error.openBoxMessage.contains("registry sign-in lookup failure for ghcr.io"))
        #expect(error.openBoxMessage.contains("Public images are pulled anonymously"))
        #expect(error.openBoxMessage.contains("sign-in details in OpenBox"))
        #expect(!error.openBoxMessage.contains("container registry"))
    }

    @Test func bundledRuntimeSignatureRequiresMatchingStoredData() throws {
        let current = BundledRuntimeSignature(
            executablePath: "/tmp/OpenBox.app/Contents/Resources/container/bin/container-apiserver",
            fileSize: 42,
            modificationTime: 123
        )
        let matchingData = try JSONEncoder().encode(current)
        let staleData = try JSONEncoder().encode(BundledRuntimeSignature(
            executablePath: current.executablePath,
            fileSize: 43,
            modificationTime: current.modificationTime
        ))

        #expect(ContainerSDKService.bundledRuntimeSignatureMatchesStored(current: current, storedData: matchingData))
        #expect(!ContainerSDKService.bundledRuntimeSignatureMatchesStored(current: current, storedData: staleData))
        #expect(!ContainerSDKService.bundledRuntimeSignatureMatchesStored(current: current, storedData: nil))
    }

    @Test func registryHostIsResolvedFromImageReference() {
        #expect(ContainerSDKService.registryHost(forImageReference: "ghcr.io/org/image:tag") == "ghcr.io")
        #expect(ContainerSDKService.registryHost(forImageReference: "localhost:5000/org/image:tag") == "localhost:5000")
    }

    @Test func builtInImageCatalogContainsMacOSBaseImage() {
        #expect(BuiltInImageCatalog.macOSBaseReference == "ghcr.io/jianliang00/macos-base:26.3")
        #expect(BuiltInImageCatalog.references == ["ghcr.io/jianliang00/macos-base:26.3"])
        #expect(BuiltInImageCatalog.contains(" ghcr.io/jianliang00/macos-base:26.3 "))
        #expect(!BuiltInImageCatalog.contains("ghcr.io/org/image:tag"))
    }

    @Test func imageDisplayOrderKeepsBuiltInImagesFirst() {
        let regularImage = OCIImageRecord(
            reference: "ghcr.io/a/regular:latest",
            digest: "",
            mediaType: "Not downloaded",
            availability: .added
        )
        let builtInImage = OCIImageRecord(
            reference: BuiltInImageCatalog.macOSBaseReference,
            digest: "",
            mediaType: "Not downloaded",
            availability: .added,
            isBuiltIn: true
        )

        let sortedReferences = [regularImage, builtInImage]
            .sorted { OCIImageRecord.displayOrder(lhs: $0, rhs: $1) }
            .map(\.reference)

        #expect(sortedReferences == [
            BuiltInImageCatalog.macOSBaseReference,
            "ghcr.io/a/regular:latest"
        ])
    }

    @Test func imagePullProgressAggregatesByteEvents() {
        var progress = ImagePullProgress(reference: "ghcr.io/org/image:tag")

        progress.apply(event: "add-total-size", value: 400)
        progress.apply(event: "add-size", value: 100)
        progress.apply(event: "add-size", value: 50)

        #expect(progress.totalBytes == 400)
        #expect(progress.downloadedBytes == 150)
        #expect(progress.fractionCompleted == 0.375)
        #expect(progress.percentLabel == "37%")
    }

    @Test func imagePullProgressFallsBackToItemProgress() throws {
        var progress = ImagePullProgress(reference: "ghcr.io/org/image:tag")

        progress.apply(event: "add-total-items", value: 4)
        progress.apply(event: "add-items", value: 1)

        let fraction = try #require(progress.fractionCompleted)
        #expect(abs(fraction - 0.25) < 0.0001)
        #expect(progress.summary == "1 of 4 items")
    }

    @Test func runtimePlatformDescriptionsIgnoreAttestationManifests() {
        let index = Index(manifests: [
            Descriptor(
                mediaType: MediaTypes.imageManifest,
                digest: "sha256:darwin",
                size: 1,
                platform: Platform(arch: "arm64", os: "darwin")
            ),
            Descriptor(
                mediaType: MediaTypes.imageManifest,
                digest: "sha256:attestation",
                size: 1,
                annotations: ["vnd.docker.reference.type": "attestation-manifest"],
                platform: Platform(arch: "arm64", os: "linux")
            )
        ])

        #expect(ContainerSDKService.runtimePlatformDescriptions(in: index) == ["darwin/arm64"])
    }

    @Test func runtimePlatformDescriptionsExpandNestedIndexes() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let contentStore = try LocalContentStore(path: directory)
        let nestedIndex = Index(manifests: [
            Descriptor(
                mediaType: MediaTypes.imageManifest,
                digest: "sha256:darwin",
                size: 1,
                platform: Platform(arch: "arm64", os: "darwin")
            )
        ])
        let nestedDescriptor = try await writeContent(
            nestedIndex,
            mediaType: MediaTypes.index,
            to: contentStore
        )
        let rootIndex = Index(manifests: [
            Descriptor(
                mediaType: MediaTypes.index,
                digest: nestedDescriptor.digest,
                size: nestedDescriptor.size,
                annotations: ["org.opencontainers.image.ref.name": "ghcr.io/jianliang00/macos-dev-agent:26.3"]
            )
        ])
        let rootDescriptor = try await writeContent(
            rootIndex,
            mediaType: MediaTypes.index,
            to: contentStore
        )

        let resolvedDescriptor = await ContainerSDKService.runtimeImageDescriptor(
            from: rootDescriptor,
            contentStore: contentStore
        )
        let platforms = await ContainerSDKService.runtimePlatformDescriptions(
            from: rootDescriptor,
            contentStore: contentStore
        )

        #expect(resolvedDescriptor.digest == nestedDescriptor.digest)
        #expect(platforms == ["darwin/arm64"])
    }

    @Test func interactiveTerminalSendsInputBytesUnchanged() throws {
        let stdin = Pipe()
        let output = Pipe()
        let terminalIO = InteractiveWorkloadIO(
            stdinHandle: stdin.fileHandleForWriting,
            outputHandle: output.fileHandleForReading
        )

        try terminalIO.send(ArraySlice<UInt8>([0x61, 0x08, 0x7f, 0x0d]))
        terminalIO.close()

        let data = stdin.fileHandleForReading.readDataToEndOfFile()
        #expect([UInt8](data) == [0x61, 0x08, 0x7f, 0x0d])
        try? output.fileHandleForWriting.close()
        try? stdin.fileHandleForReading.close()
    }

    @Test func staleTerminalOutputHandlerTokenDoesNotClearCurrentHandler() throws {
        let stdin = Pipe()
        let output = Pipe()
        let terminalIO = InteractiveWorkloadIO(
            stdinHandle: stdin.fileHandleForWriting,
            outputHandle: output.fileHandleForReading
        )
        let receivedSignal = DispatchSemaphore(value: 0)
        let received = LockedData()

        let staleHandlerID = terminalIO.setOutputHandler { _ in }
        _ = terminalIO.setOutputHandler { data in
            received.append(data)
            receivedSignal.signal()
        }

        terminalIO.clearOutputHandler(id: staleHandlerID)
        try output.fileHandleForWriting.write(contentsOf: Data("ok".utf8))

        let result = receivedSignal.wait(timeout: .now() + 1)
        #expect(result == .success)
        #expect(received.value == Data("ok".utf8))

        terminalIO.close()
        try? output.fileHandleForWriting.close()
        try? stdin.fileHandleForReading.close()
    }

    @Test func interactiveTerminalCachesSessionObjects() throws {
        let stdin = Pipe()
        let output = Pipe()
        let terminalIO = InteractiveWorkloadIO(
            stdinHandle: stdin.fileHandleForWriting,
            outputHandle: output.fileHandleForReading
        )

        let first: NSObject = terminalIO.cachedSessionObject(forKey: "terminal-view") {
            NSObject()
        }
        let second: NSObject = terminalIO.cachedSessionObject(forKey: "terminal-view") {
            NSObject()
        }
        let other: NSObject = terminalIO.cachedSessionObject(forKey: "other") {
            NSObject()
        }

        #expect(first === second)
        #expect(first !== other)

        terminalIO.close()
        try? output.fileHandleForWriting.close()
        try? stdin.fileHandleForReading.close()
    }

    @Test func terminalGridSizeRejectsNonPositiveDimensions() {
        #expect(TerminalGridSize(columns: 94, rows: 21) != nil)
        #expect(TerminalGridSize(columns: 0, rows: 21) == nil)
        #expect(TerminalGridSize(columns: 94, rows: 0) == nil)
        #expect(TerminalGridSize(columns: -2, rows: 21) == nil)
    }

    @Test func terminalBackendResizeStateSendsOnlyChangedSizes() throws {
        let state = TerminalBackendResizeState()
        let initial = try #require(TerminalGridSize(columns: 94, rows: 21))
        let changed = try #require(TerminalGridSize(columns: 95, rows: 21))

        #expect(state.shouldSend(initial))
        #expect(!state.shouldSend(initial))
        #expect(state.shouldSend(changed))
        #expect(!state.shouldSend(changed))
    }

    @MainActor
    @Test func terminalContainerInstallPreservesCachedTerminalFrameUntilLayout() throws {
        let stdin = Pipe()
        let output = Pipe()
        let terminalIO = InteractiveWorkloadIO(
            stdinHandle: stdin.fileHandleForWriting,
            outputHandle: output.fileHandleForReading
        )
        let cachedFrame = CGRect(origin: .zero, size: CGSize(width: 720, height: 320))
        let terminalView = TerminalView(
            frame: cachedFrame,
            font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        )
        let container = TerminalContainerView(
            frame: CGRect(origin: .zero, size: CGSize(width: 960, height: 320))
        )

        container.install(terminalView, representedBy: terminalIO)

        #expect(terminalView.frame.size == cachedFrame.size)
        #expect(terminalView.autoresizingMask.isEmpty)

        terminalIO.close()
        try? output.fileHandleForWriting.close()
        try? stdin.fileHandleForReading.close()
    }

    @Test func terminalOutputImageFilterStripsKittyGraphicsAcrossChunks() {
        let escape: UInt8 = 0x1b
        let filter = TerminalOutputImageFilter()
        let firstChunk = [UInt8(ascii: "a"), escape, UInt8(ascii: "_")]
            + Array("Gf=100,s=1,v=1;payload".utf8)
        let secondChunk = [escape, UInt8(ascii: "\\"), UInt8(ascii: "b")]

        #expect(filter.filter(firstChunk) == [UInt8(ascii: "a")])
        #expect(filter.filter(secondChunk) == [UInt8(ascii: "b")])
    }

    @Test func terminalOutputImageFilterStripsITermInlineImageAcrossChunks() {
        let escape: UInt8 = 0x1b
        let filter = TerminalOutputImageFilter()
        let firstChunk = [UInt8(ascii: "a"), escape, UInt8(ascii: "]")]
            + Array("1337;File=inline=1:abcdef".utf8)
        let secondChunk = [UInt8(ascii: "\u{07}"), UInt8(ascii: "b")]

        #expect(filter.filter(firstChunk) == [UInt8(ascii: "a")])
        #expect(filter.filter(secondChunk) == [UInt8(ascii: "b")])
    }

    @Test func terminalOutputImageFilterStripsSixelButPreservesDCSQuery() {
        let escape: UInt8 = 0x1b
        let sixelFilter = TerminalOutputImageFilter()
        let sixel = [UInt8(ascii: "a"), escape, UInt8(ascii: "P")]
            + Array("0;0;0q????".utf8)
            + [escape, UInt8(ascii: "\\"), UInt8(ascii: "b")]

        #expect(sixelFilter.filter(sixel) == [UInt8(ascii: "a"), UInt8(ascii: "b")])

        let queryFilter = TerminalOutputImageFilter()
        let dcsQuery = [escape, UInt8(ascii: "P")] + Array("$qq".utf8) + [escape, UInt8(ascii: "\\")]

        #expect(queryFilter.filter(dcsQuery) == dcsQuery)
    }

    @Test func terminalOutputImageFilterPreservesDCSAndRegularTerminalSequences() {
        let escape: UInt8 = 0x1b
        let filter = TerminalOutputImageFilter()
        let dcsQuery = [escape, UInt8(ascii: "P")] + Array("$qq".utf8) + [escape, UInt8(ascii: "\\")]
        let titleSequence = [escape, UInt8(ascii: "]")]
            + Array("0;OpenBox".utf8)
            + [UInt8(ascii: "\u{07}")]
        let colorSequence = [escape, UInt8(ascii: "[")] + Array("31m".utf8)
        let bytes = [UInt8(ascii: "a")] + dcsQuery + titleSequence + colorSequence + [UInt8(ascii: "b")]

        #expect(filter.filter(bytes) == bytes)
    }

    @Test func terminalStartupFrameNormalizerClearsBeforeFirstSynchronizedTopRepaint() {
        let normalizer = TerminalStartupFrameNormalizer()
        normalizer.observeInput(Array("\r".utf8))

        let frame = Array("\u{1B}[?2026h\u{1B}[1;55H\u{1B}[0m\u{1B}[49m\u{1B}[KWelcome\u{1B}[?2026l".utf8)
        let result = normalizer.normalize(frame)

        #expect(result.action == .prependedClear)
        #expect(result.bytes.starts(with: Array("\u{1B}[2J\u{1B}[H".utf8)))
        #expect(result.bytes.suffix(frame.count).elementsEqual(frame))
    }

    @Test func terminalStartupFrameNormalizerPreservesAlreadyClearedFrame() {
        let normalizer = TerminalStartupFrameNormalizer()
        normalizer.observeInput(Array("\r".utf8))

        let frame = Array("\u{1B}[?2026h\u{1B}[2J\u{1B}[HWelcome\u{1B}[?2026l".utf8)
        let result = normalizer.normalize(frame)

        #expect(result.action == .unchanged)
        #expect(result.bytes == frame)
    }

    @Test func terminalStartupFrameNormalizerPreservesRegularCommandOutput() {
        let normalizer = TerminalStartupFrameNormalizer()
        normalizer.observeInput(Array("\r".utf8))

        let output = Array("Applications\nLibrary\nSystem\n".utf8)
        let result = normalizer.normalize(output)

        #expect(result.action == .unchanged)
        #expect(result.bytes == output)
    }

    @Test func terminalStartupFrameNormalizerDoesNotClearAfterInterrupt() {
        let normalizer = TerminalStartupFrameNormalizer()
        normalizer.observeInput([0x03])

        let frame = Array("\u{1B}[?2026h\u{1B}[1;55H\u{1B}[0m\u{1B}[49m\u{1B}[KInterrupted\u{1B}[?2026l".utf8)
        let result = normalizer.normalize(frame)

        #expect(result.action == .unchanged)
        #expect(result.bytes == frame)
    }

    @Test func terminalStartupFrameNormalizerBuffersSplitSynchronizedPrefix() {
        let normalizer = TerminalStartupFrameNormalizer()
        normalizer.observeInput(Array("\r".utf8))

        let prefix = Array("\u{1B}[?2026h".utf8)
        let prefixResult = normalizer.normalize(prefix)
        #expect(prefixResult.action == .buffered)
        #expect(prefixResult.bytes.isEmpty)

        let body = Array("\u{1B}[2;2HWelcome\u{1B}[?2026l".utf8)
        let bodyResult = normalizer.normalize(body)

        #expect(bodyResult.action == .prependedClear)
        #expect(bodyResult.bytes.starts(with: Array("\u{1B}[2J\u{1B}[H".utf8)))
        #expect(bodyResult.bytes.suffix(prefix.count + body.count).elementsEqual(prefix + body))
    }

    @Test func terminalResponseFilterStripsKittyGraphicsCapabilityResponse() {
        let escape: UInt8 = 0x1b
        let bytes = [UInt8(ascii: "a"), escape, UInt8(ascii: "_")]
            + Array("Gi=1;OK".utf8)
            + [escape, UInt8(ascii: "\\"), UInt8(ascii: "b")]

        #expect(
            TerminalResponseFilter.removingKittyGraphicsResponses(from: bytes[...]) == [
                UInt8(ascii: "a"),
                UInt8(ascii: "b")
            ]
        )
    }

    @Test func terminalResponseFilterPreservesEscapeKeyAndRegularTerminalInput() {
        let escape: UInt8 = 0x1b
        let escapeKey = [escape]
        let cursorLeft = [escape, UInt8(ascii: "[")] + Array("D".utf8)
        let titleSequence = [escape, UInt8(ascii: "]")]
            + Array("0;OpenBox".utf8)
            + [UInt8(ascii: "\u{07}")]

        #expect(TerminalResponseFilter.removingKittyGraphicsResponses(from: escapeKey[...]) == escapeKey)
        #expect(
            TerminalResponseFilter.removingKittyGraphicsResponses(from: cursorLeft[...]) == cursorLeft
        )
        #expect(
            TerminalResponseFilter.removingKittyGraphicsResponses(from: titleSequence[...]) == titleSequence
        )
    }

    @Test func terminalResponseFilterPassesIncompleteKittyResponseThrough() {
        let escape: UInt8 = 0x1b
        let bytes = [escape, UInt8(ascii: "_")] + Array("Gi=1;OK".utf8)

        #expect(TerminalResponseFilter.removingKittyGraphicsResponses(from: bytes[...]) == bytes)
    }

    @Test func interactiveTerminalEnvironmentPreservesBasePathAndAddsTerminalDefaults() {
        let environment = ContainerSDKService.makeInteractiveTerminalEnvironment(
            baseEnvironment: [
                "PATH=/custom/bin:/usr/bin",
                "HOME=/Users/admin"
            ],
            shellPath: "/bin/zsh"
        )
        let values = environmentDictionary(environment)

        #expect(values["PATH"]?.hasPrefix("/custom/bin:/usr/bin") == true)
        #expect(values["PATH"]?.contains("/opt/homebrew/bin") == true)
        #expect(values["TERM"] == "xterm-256color")
        #expect(values["COLORTERM"] == "truecolor")
        #expect(values["LANG"] == "en_US.UTF-8")
        #expect(values["LC_CTYPE"] == "en_US.UTF-8")
        #expect(values["SHELL"] == "/bin/zsh")
        #expect(values["USER"] == "admin")
        #expect(values["LOGNAME"] == "admin")
    }

    @Test func interactiveTerminalEnvironmentOverridesNonUTF8Locale() {
        let environment = ContainerSDKService.makeInteractiveTerminalEnvironment(
            baseEnvironment: [
                "PATH=/usr/bin",
                "LANG=C",
                "LC_ALL=C"
            ],
            shellPath: "/bin/zsh"
        )
        let values = environmentDictionary(environment)

        #expect(values["LANG"] == "en_US.UTF-8")
        #expect(values["LC_ALL"] == "en_US.UTF-8")
        #expect(values["LC_CTYPE"] == "en_US.UTF-8")
    }

    private func environmentDictionary(_ environment: [String]) -> [String: String] {
        var values: [String: String] = [:]
        for entry in environment {
            guard let separator = entry.firstIndex(of: "=") else { continue }
            let key = String(entry[..<separator])
            let value = String(entry[entry.index(after: separator)...])
            values[key] = value
        }
        return values
    }
}
