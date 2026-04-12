//
//  EmbeddedTerminalView.swift
//  OpenBox
//
//  Created by Codex on 2026/4/11.
//

import AppKit
import SwiftTerm
import SwiftUI

struct TerminalDiagnosticsContext: Equatable {
    let sandboxID: String
    let workloadID: String

    var logURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("openbox-terminal-\(Self.safeFileComponent(workloadID)).log")
    }

    private static func safeFileComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" })
    }
}

struct EmbeddedTerminalView: NSViewRepresentable {
    let terminalIO: InteractiveWorkloadIO
    let allowsInlineGraphics: Bool
    let diagnostics: TerminalDiagnosticsContext?
    let onResize: (Int, Int) -> Void
    let onError: (Error) -> Void

    private static let defaultSize = CGSize(width: 960, height: 320)
    private static let terminalViewSessionKey = "OpenBox.EmbeddedTerminalView.TerminalView"

    func makeCoordinator() -> Coordinator {
        Coordinator(
            allowsInlineGraphics: allowsInlineGraphics,
            diagnostics: diagnostics,
            onResize: onResize,
            onError: onError
        )
    }

    func makeNSView(context: Context) -> TerminalContainerView {
        let container = TerminalContainerView(frame: CGRect(origin: .zero, size: Self.defaultSize))
        container.allowsInlineGraphics = allowsInlineGraphics
        let terminalView = Self.terminalView(for: terminalIO)
        Self.configure(terminalView, coordinator: context.coordinator, allowsInlineGraphics: allowsInlineGraphics)

        container.onLayout = { [weak coordinator = context.coordinator] terminalView in
            coordinator?.recordLayout(terminalView)
        }
        container.onReadyForIO = { [weak coordinator = context.coordinator, terminalIO] terminalView in
            coordinator?.bind(terminalIO: terminalIO, terminalView: terminalView)
        }
        container.install(terminalView, representedBy: terminalIO)

        DispatchQueue.main.async {
            terminalView.window?.makeFirstResponder(terminalView)
        }

        return container
    }

    func updateNSView(_ container: TerminalContainerView, context: Context) {
        context.coordinator.onResize = onResize
        context.coordinator.onError = onError
        context.coordinator.setDiagnostics(diagnostics)
        context.coordinator.setAllowsInlineGraphics(allowsInlineGraphics)
        container.allowsInlineGraphics = allowsInlineGraphics
        if container.representedTerminalIO !== terminalIO {
            context.coordinator.unbind()
            let terminalView = Self.terminalView(for: terminalIO)
            Self.configure(terminalView, coordinator: context.coordinator, allowsInlineGraphics: allowsInlineGraphics)
            container.install(terminalView, representedBy: terminalIO)
        } else if let terminalView = container.terminalView {
            Self.configure(terminalView, coordinator: context.coordinator, allowsInlineGraphics: allowsInlineGraphics)
        }
        container.onLayout = { [weak coordinator = context.coordinator] terminalView in
            coordinator?.recordLayout(terminalView)
        }
        container.onReadyForIO = { [weak coordinator = context.coordinator, terminalIO] terminalView in
            coordinator?.bind(terminalIO: terminalIO, terminalView: terminalView)
        }
        if container.isReadyForIO, let terminalView = container.terminalView {
            context.coordinator.bind(terminalIO: terminalIO, terminalView: terminalView)
        }
        if !container.isReadyForIO {
            container.needsLayout = true
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: TerminalContainerView,
        context: Context
    ) -> CGSize? {
        CGSize(
            width: proposal.width ?? Self.defaultSize.width,
            height: proposal.height ?? Self.defaultSize.height
        )
    }

    static func dismantleNSView(_ container: TerminalContainerView, coordinator: Coordinator) {
        coordinator.unbind()
        container.onLayout = nil
        container.terminalView?.terminalDelegate = nil
        container.detachTerminalView()
    }

    private static func terminalView(for terminalIO: InteractiveWorkloadIO) -> TerminalView {
        terminalIO.cachedSessionObject(forKey: terminalViewSessionKey) {
            TerminalView(
                frame: CGRect(origin: .zero, size: defaultSize),
                font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            )
        }
    }

    private static func configure(
        _ terminalView: TerminalView,
        coordinator: Coordinator,
        allowsInlineGraphics: Bool
    ) {
        terminalView.terminalDelegate = coordinator
        terminalView.configureNativeColors()
        terminalView.nativeForegroundColor = NSColor(calibratedWhite: 0.92, alpha: 1.0)
        terminalView.nativeBackgroundColor = NSColor(calibratedWhite: 0.035, alpha: 1.0)
        configureEmbeddedTerminalCapabilities(terminalView, allowsInlineGraphics: allowsInlineGraphics)
        terminalView.caretViewTracksFocus = true
        terminalView.backspaceSendsControlH = false
        terminalView.allowMouseReporting = true
        terminalView.autoresizingMask = [.width, .height]
    }

    final class Coordinator: NSObject, TerminalViewDelegate, @unchecked Sendable {
        var onResize: (Int, Int) -> Void
        var onError: (Error) -> Void

        private weak var terminalView: TerminalView?
        private var terminalIO: InteractiveWorkloadIO?
        private var outputHandlerID: UUID?
        private var lastSize: (columns: Int, rows: Int)?
        private var allowsInlineGraphics: Bool
        private let outputImageFilter = TerminalOutputImageFilter()
        private let startupFrameNormalizer = TerminalStartupFrameNormalizer()
        private var diagnostics: TerminalDiagnosticsContext?
        private var diagnosticLogger: TerminalDiagnosticLogger?
        private var outputChunkCount = 0
        private var responseChunkCount = 0
        private var lastLayoutSummary: String?
        private let maxDiagnosticOutputChunks = 400
        private let maxDiagnosticResponseChunks = 400

        init(
            allowsInlineGraphics: Bool,
            diagnostics: TerminalDiagnosticsContext?,
            onResize: @escaping (Int, Int) -> Void,
            onError: @escaping (Error) -> Void
        ) {
            self.allowsInlineGraphics = allowsInlineGraphics
            self.diagnostics = diagnostics
            self.diagnosticLogger = diagnostics.map { TerminalDiagnosticLogger(context: $0) }
            self.onResize = onResize
            self.onError = onError
            diagnosticLogger?.event("coordinator init \(Self.diagnosticSummary(for: diagnostics))")
        }

        func setAllowsInlineGraphics(_ allowsInlineGraphics: Bool) {
            guard self.allowsInlineGraphics != allowsInlineGraphics else { return }
            self.allowsInlineGraphics = allowsInlineGraphics
            outputImageFilter.reset()
            diagnosticLogger?.event("inline graphics changed enabled=\(allowsInlineGraphics)")
        }

        func setDiagnostics(_ diagnostics: TerminalDiagnosticsContext?) {
            guard self.diagnostics != diagnostics else { return }
            diagnosticLogger?.event("diagnostics disabled")
            self.diagnostics = diagnostics
            outputChunkCount = 0
            responseChunkCount = 0
            lastLayoutSummary = nil
            diagnosticLogger = diagnostics.map { TerminalDiagnosticLogger(context: $0) }
            diagnosticLogger?.event("diagnostics enabled \(Self.diagnosticSummary(for: diagnostics))")
        }

        func recordLayout(_ terminalView: TerminalView) {
            let summary = Self.layoutSummary(for: terminalView)
            guard lastLayoutSummary != summary else { return }
            lastLayoutSummary = summary
            diagnosticLogger?.event("layout \(summary)")
        }

        func bind(terminalIO: InteractiveWorkloadIO, terminalView: TerminalView) {
            let isSameIO = self.terminalIO === terminalIO
            let isSameView = self.terminalView === terminalView
            self.terminalView = terminalView
            diagnosticLogger?.event("bind requested sameIO=\(isSameIO) sameView=\(isSameView) \(Self.layoutSummary(for: terminalView))")
            guard !isSameIO || !isSameView else { return }

            if !isSameIO {
                diagnosticLogger?.event("clearing previous output handler id=\(outputHandlerID?.uuidString ?? "nil")")
                self.terminalIO?.clearOutputHandler(id: outputHandlerID)
                self.terminalIO = terminalIO
                outputHandlerID = nil
            }
            if !isSameIO || !isSameView {
                outputImageFilter.reset()
                startupFrameNormalizer.reset()
                outputChunkCount = 0
                responseChunkCount = 0
                diagnosticLogger?.event("reset terminal stream filters")
            }
            synchronizeSize(from: terminalView, force: true)
            outputHandlerID = terminalIO.setOutputHandler { [weak self, weak terminalIO] data in
                let bytes = [UInt8](data)
                DispatchQueue.main.async {
                    guard let self, let terminalIO, self.terminalIO === terminalIO, let terminalView = self.terminalView else { return }
                    self.outputChunkCount += 1
                    if self.outputChunkCount <= self.maxDiagnosticOutputChunks {
                        self.diagnosticLogger?.bytes("pty-out raw #\(self.outputChunkCount)", bytes)
                    } else if self.outputChunkCount == self.maxDiagnosticOutputChunks + 1 {
                        self.diagnosticLogger?.event("pty-out logging suppressed after \(self.maxDiagnosticOutputChunks) chunks")
                    }
                    let filteredBytes = self.allowsInlineGraphics ? bytes : self.outputImageFilter.filter(bytes)
                    if self.outputChunkCount <= self.maxDiagnosticOutputChunks && (filteredBytes.count != bytes.count || filteredBytes != bytes) {
                        self.diagnosticLogger?.bytes("pty-out filtered #\(self.outputChunkCount)", filteredBytes)
                    }
                    guard !filteredBytes.isEmpty else { return }
                    let normalizedOutput = self.startupFrameNormalizer.normalize(filteredBytes)
                    switch normalizedOutput.action {
                    case .unchanged:
                        break
                    case .buffered:
                        self.diagnosticLogger?.event("startup frame normalizer buffered synchronized output prefix")
                    case .prependedClear:
                        self.diagnosticLogger?.event("startup frame normalizer prepended clear-screen before synchronized top repaint")
                    }
                    guard !normalizedOutput.bytes.isEmpty else { return }
                    terminalView.feed(byteArray: normalizedOutput.bytes[...])
                }
            }
            diagnosticLogger?.event("installed output handler id=\(outputHandlerID?.uuidString ?? "nil")")
        }

        func unbind() {
            diagnosticLogger?.event("unbind outputHandlerID=\(outputHandlerID?.uuidString ?? "nil")")
            terminalIO?.clearOutputHandler(id: outputHandlerID)
            terminalIO = nil
            outputHandlerID = nil
            terminalView = nil
            outputImageFilter.reset()
            startupFrameNormalizer.reset()
        }

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            do {
                let filteredData: [UInt8]
                if allowsInlineGraphics {
                    filteredData = Array(data)
                } else {
                    filteredData = TerminalResponseFilter.removingKittyGraphicsResponses(from: data)
                }
                responseChunkCount += 1
                if responseChunkCount <= maxDiagnosticResponseChunks {
                    diagnosticLogger?.bytes("terminal-response raw #\(responseChunkCount)", Array(data))
                } else if responseChunkCount == maxDiagnosticResponseChunks + 1 {
                    diagnosticLogger?.event("terminal-response logging suppressed after \(maxDiagnosticResponseChunks) chunks")
                }
                if responseChunkCount <= maxDiagnosticResponseChunks && filteredData != Array(data) {
                    diagnosticLogger?.bytes("terminal-response filtered #\(responseChunkCount)", filteredData)
                }
                guard !filteredData.isEmpty else { return }
                startupFrameNormalizer.observeInput(filteredData)
                try terminalIO?.send(filteredData[...])
            } catch {
                DispatchQueue.main.async { [onError] in
                    onError(error)
                }
            }
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            diagnosticLogger?.event("sizeChanged cols=\(newCols) rows=\(newRows) \(Self.layoutSummary(for: source))")
            synchronizeSize(columns: newCols, rows: newRows, force: false)
        }

        func setTerminalTitle(source: TerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func scrolled(source: TerminalView, position: Double) {}

        func clipboardCopy(source: TerminalView, content: Data) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setData(content, forType: .string)
        }

        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

        private func synchronizeSize(from terminalView: TerminalView, force: Bool) {
            let dims = terminalView.terminal.getDims()
            synchronizeSize(columns: dims.cols, rows: dims.rows, force: force)
        }

        private func synchronizeSize(columns newCols: Int, rows newRows: Int, force: Bool) {
            let columns = max(1, newCols)
            let rows = max(1, newRows)
            guard force || lastSize?.columns != columns || lastSize?.rows != rows else { return }

            diagnosticLogger?.event("resize sync force=\(force) previous=\(lastSize?.columns ?? 0)x\(lastSize?.rows ?? 0) next=\(columns)x\(rows)")
            lastSize = (columns, rows)
            onResize(columns, rows)
        }

        private static func diagnosticSummary(for diagnostics: TerminalDiagnosticsContext?) -> String {
            guard let diagnostics else { return "context=nil" }
            return "sandbox=\(diagnostics.sandboxID) workload=\(diagnostics.workloadID) log=\(diagnostics.logURL.path)"
        }

        private static func layoutSummary(for terminalView: TerminalView) -> String {
            let dims = terminalView.terminal.getDims()
            return "bounds=\(format(terminalView.bounds)) frame=\(format(terminalView.frame)) dims=\(dims.cols)x\(dims.rows)"
        }

        private static func format(_ rect: CGRect) -> String {
            "\(format(rect.origin.x)),\(format(rect.origin.y)),\(format(rect.size.width))x\(format(rect.size.height))"
        }

        private static func format(_ value: CGFloat) -> String {
            String(format: "%.1f", Double(value))
        }
    }
}

final class TerminalContainerView: NSView {
    private(set) var terminalView: TerminalView?
    private(set) weak var representedTerminalIO: InteractiveWorkloadIO?
    private(set) var isReadyForIO = false
    var onReadyForIO: ((TerminalView) -> Void)?
    var onLayout: ((TerminalView) -> Void)?
    var allowsInlineGraphics = false {
        didSet {
            guard oldValue != allowsInlineGraphics, let terminalView else { return }
            configureEmbeddedTerminalCapabilities(terminalView, allowsInlineGraphics: allowsInlineGraphics)
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        if #available(macOS 14, *) {
            clipsToBounds = true
        }
    }

    func install(_ terminalView: TerminalView, representedBy terminalIO: InteractiveWorkloadIO) {
        self.terminalView?.removeFromSuperview()
        terminalView.removeFromSuperview()
        self.terminalView = terminalView
        representedTerminalIO = terminalIO
        configureEmbeddedTerminalCapabilities(terminalView, allowsInlineGraphics: allowsInlineGraphics)
        isReadyForIO = false
        if bounds.width > 0, bounds.height > 0 {
            terminalView.frame = bounds
        }
        addSubview(terminalView)
        needsLayout = true
    }

    func detachTerminalView() {
        terminalView?.removeFromSuperview()
        terminalView = nil
        representedTerminalIO = nil
        isReadyForIO = false
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
        DispatchQueue.main.async { [weak self] in
            self?.focusTerminalIfPossible()
        }
    }

    override func mouseDown(with event: NSEvent) {
        focusTerminalIfPossible()
        super.mouseDown(with: event)
    }

    override func layout() {
        super.layout()
        guard let terminalView else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        prepareTerminalLayout(terminalView)
        onLayout?(terminalView)

        guard !isReadyForIO, window != nil else { return }
        isReadyForIO = true
        DispatchQueue.main.async { [weak self, weak terminalView] in
            guard let self, let terminalView, self.terminalView === terminalView, self.isReadyForIO else { return }
            self.prepareTerminalLayout(terminalView)
            self.onLayout?(terminalView)
            self.onReadyForIO?(terminalView)
            self.focusTerminalIfPossible()
        }
    }

    private func prepareTerminalLayout(_ terminalView: TerminalView) {
        configureEmbeddedTerminalCapabilities(terminalView, allowsInlineGraphics: allowsInlineGraphics)
        terminalView.setFrameOrigin(.zero)
        terminalView.setFrameSize(bounds.size)
        terminalView.needsDisplay = true
        terminalView.layoutSubtreeIfNeeded()
    }

    private func focusTerminalIfPossible() {
        guard let terminalView, terminalView.window != nil else { return }
        terminalView.window?.makeFirstResponder(terminalView)
    }
}

private func configureEmbeddedTerminalCapabilities(_ terminalView: TerminalView, allowsInlineGraphics: Bool) {
    terminalView.terminal.options.enableSixelReported = allowsInlineGraphics
    terminalView.layer?.isOpaque = true
    terminalView.layer?.backgroundColor = terminalView.nativeBackgroundColor.cgColor
}

final class TerminalDiagnosticLogger {
    private let url: URL
    private let lock = NSLock()
    private let timestampFormatter = ISO8601DateFormatter()

    init(context: TerminalDiagnosticsContext) {
        self.url = context.logURL
        append("\n=== OpenBox terminal diagnostics \(timestamp()) ===\n")
    }

    func event(_ message: String) {
        append("[\(timestamp())] EVENT \(message)\n")
    }

    func bytes(_ label: String, _ bytes: [UInt8]) {
        append("[\(timestamp())] BYTES \(label) count=\(bytes.count)\n\(Self.escaped(bytes))\n")
    }

    private func append(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        lock.withLock {
            let directory = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let handle = try FileHandle(forWritingTo: url)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } catch {
                    return
                }
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    private func timestamp() -> String {
        timestampFormatter.string(from: Date())
    }

    private static func escaped(_ bytes: [UInt8], limit: Int = 4096) -> String {
        var output = ""
        output.reserveCapacity(min(bytes.count, limit))

        for byte in bytes.prefix(limit) {
            switch byte {
            case 0x08:
                output += "\\b"
            case 0x09:
                output += "\\t"
            case 0x0a:
                output += "\\n\n"
            case 0x0d:
                output += "\\r"
            case 0x1b:
                output += "\\e"
            case 0x20...0x7e:
                output.append(Character(UnicodeScalar(byte)))
            case 0x7f:
                output += "\\x7F"
            default:
                output += String(format: "\\x%02X", byte)
            }
        }

        if bytes.count > limit {
            output += "\n... truncated \(bytes.count - limit) bytes ..."
        }

        return output
    }
}

final class TerminalStartupFrameNormalizer {
    enum Action {
        case unchanged
        case buffered
        case prependedClear
    }

    struct Result {
        let bytes: [UInt8]
        let action: Action
    }

    private static let escape: UInt8 = 0x1b
    private static let csi: UInt8 = 0x9b
    private static let synchronizedOutputStart = Array("\u{1B}[?2026h".utf8)
    private static let clearScreenAndHome = Array("\u{1B}[2J\u{1B}[H".utf8)
    private static let explicitScreenResetSequences = [
        Array("\u{1B}[2J".utf8),
        Array("\u{1B}[3J".utf8),
        Array("\u{1B}[?47h".utf8),
        Array("\u{1B}[?1047h".utf8),
        Array("\u{1B}[?1049h".utf8)
    ]

    private let maxBufferedPrefixBytes: Int
    private var awaitingCommandFrame = false
    private var bufferedSynchronizedPrefix: [UInt8] = []

    init(maxBufferedPrefixBytes: Int = 8192) {
        self.maxBufferedPrefixBytes = maxBufferedPrefixBytes
    }

    func observeInput(_ bytes: [UInt8]) {
        if bytes.contains(0x03) || bytes.contains(0x04) {
            reset()
            return
        }

        if bytes.contains(0x0d) || bytes.contains(0x0a) {
            awaitingCommandFrame = true
            bufferedSynchronizedPrefix.removeAll(keepingCapacity: true)
        }
    }

    func reset() {
        awaitingCommandFrame = false
        bufferedSynchronizedPrefix.removeAll(keepingCapacity: true)
    }

    func normalize(_ bytes: [UInt8]) -> Result {
        guard awaitingCommandFrame || !bufferedSynchronizedPrefix.isEmpty else {
            return Result(bytes: bytes, action: .unchanged)
        }

        let candidate: [UInt8]
        if bufferedSynchronizedPrefix.isEmpty {
            candidate = bytes
        } else {
            candidate = bufferedSynchronizedPrefix + bytes
        }

        if Self.containsExplicitScreenReset(candidate) {
            reset()
            return Result(bytes: candidate, action: .unchanged)
        }

        if Self.containsSynchronizedOutputStart(candidate), Self.containsTopCursorPosition(candidate) {
            reset()
            return Result(bytes: Self.clearScreenAndHome + candidate, action: .prependedClear)
        }

        if !bufferedSynchronizedPrefix.isEmpty {
            if Self.containsVisibleText(candidate) || candidate.count > maxBufferedPrefixBytes {
                reset()
                return Result(bytes: candidate, action: .unchanged)
            }
            bufferedSynchronizedPrefix = candidate
            return Result(bytes: [], action: .buffered)
        }

        if Self.containsSynchronizedOutputStart(bytes), !Self.containsVisibleText(bytes) {
            bufferedSynchronizedPrefix = bytes
            return Result(bytes: [], action: .buffered)
        }

        if Self.containsVisibleText(bytes) {
            reset()
        }

        return Result(bytes: bytes, action: .unchanged)
    }

    private static func containsSynchronizedOutputStart(_ bytes: [UInt8]) -> Bool {
        containsSequence(synchronizedOutputStart, in: bytes)
    }

    private static func containsExplicitScreenReset(_ bytes: [UInt8]) -> Bool {
        explicitScreenResetSequences.contains { containsSequence($0, in: bytes) }
    }

    private static func containsTopCursorPosition(_ bytes: [UInt8]) -> Bool {
        forEachCSI(in: bytes) { parameters, final in
            guard final == UInt8(ascii: "H") || final == UInt8(ascii: "f") else {
                return false
            }
            return firstCSIParameter(in: parameters, defaultValue: 1) <= 3
        }
    }

    private static func firstCSIParameter(in parameters: ArraySlice<UInt8>, defaultValue: Int) -> Int {
        var index = parameters.startIndex
        if index < parameters.endIndex, parameters[index] == UInt8(ascii: "?") {
            index = parameters.index(after: index)
        }
        guard index < parameters.endIndex, parameters[index] != UInt8(ascii: ";") else {
            return defaultValue
        }

        var value = 0
        var sawDigit = false
        while index < parameters.endIndex {
            let byte = parameters[index]
            guard byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") else {
                break
            }
            sawDigit = true
            value = value * 10 + Int(byte - UInt8(ascii: "0"))
            index = parameters.index(after: index)
        }
        return sawDigit ? value : defaultValue
    }

    private static func forEachCSI(in bytes: [UInt8], match: (ArraySlice<UInt8>, UInt8) -> Bool) -> Bool {
        var index = 0
        while index < bytes.count {
            let start: Int
            if bytes[index] == escape, index + 1 < bytes.count, bytes[index + 1] == UInt8(ascii: "[") {
                start = index + 2
            } else if bytes[index] == csi {
                start = index + 1
            } else {
                index += 1
                continue
            }

            var cursor = start
            while cursor < bytes.count {
                let byte = bytes[cursor]
                if byte >= 0x40, byte <= 0x7e {
                    if match(bytes[start..<cursor], byte) {
                        return true
                    }
                    index = cursor + 1
                    break
                }
                cursor += 1
            }

            if cursor >= bytes.count {
                break
            }
        }
        return false
    }

    private static func containsVisibleText(_ bytes: [UInt8]) -> Bool {
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            switch byte {
            case escape:
                index = indexAfterEscapeSequence(in: bytes, startingAt: index)
            case csi:
                index = indexAfterCSI(in: bytes, startingAt: index + 1)
            case 0x90, 0x9d, 0x9f:
                index = indexAfterTerminalString(in: bytes, startingAt: index + 1)
            case 0x20...0x7e, 0xc2...0xf4:
                return true
            default:
                index += 1
            }
        }
        return false
    }

    private static func indexAfterEscapeSequence(in bytes: [UInt8], startingAt index: Int) -> Int {
        let nextIndex = index + 1
        guard nextIndex < bytes.count else { return bytes.count }

        switch bytes[nextIndex] {
        case UInt8(ascii: "["):
            return indexAfterCSI(in: bytes, startingAt: nextIndex + 1)
        case UInt8(ascii: "]"), UInt8(ascii: "_"), UInt8(ascii: "P"):
            return indexAfterTerminalString(in: bytes, startingAt: nextIndex + 1)
        default:
            return min(nextIndex + 1, bytes.count)
        }
    }

    private static func indexAfterCSI(in bytes: [UInt8], startingAt index: Int) -> Int {
        var cursor = index
        while cursor < bytes.count {
            let byte = bytes[cursor]
            if byte >= 0x40, byte <= 0x7e {
                return cursor + 1
            }
            cursor += 1
        }
        return bytes.count
    }

    private static func indexAfterTerminalString(in bytes: [UInt8], startingAt index: Int) -> Int {
        var cursor = index
        var sawEscape = false
        while cursor < bytes.count {
            let byte = bytes[cursor]

            if sawEscape {
                if byte == UInt8(ascii: "\\") {
                    return cursor + 1
                }
                sawEscape = byte == escape
                cursor += 1
                continue
            }

            if byte == escape {
                sawEscape = true
                cursor += 1
                continue
            }

            if byte == 0x07 || byte == 0x9c {
                return cursor + 1
            }

            cursor += 1
        }
        return bytes.count
    }

    private static func containsSequence(_ needle: [UInt8], in haystack: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        for index in 0...(haystack.count - needle.count) {
            if haystack[index..<(index + needle.count)].elementsEqual(needle) {
                return true
            }
        }
        return false
    }
}

final class TerminalOutputImageFilter {
    private enum DetectionDecision {
        case wait
        case strip
        case passThrough
    }

    private enum SequenceKind {
        case osc
        case apc
        case dcs
    }

    private enum State {
        case normal
        case escape
        case detectingTerminalString(SequenceKind)
        case strippingTerminalString(SequenceKind)
        case passingThroughTerminalString(SequenceKind)
    }

    private let maxDetectionBytes: Int
    private let maxStrippedSequenceBytes: Int
    private var state: State = .normal
    private var buffer: [UInt8] = []
    private var terminalStringSawEscape = false
    private var strippedSequenceBytes = 0

    init(maxDetectionBytes: Int = 64, maxStrippedSequenceBytes: Int = 4 * 1024 * 1024) {
        self.maxDetectionBytes = maxDetectionBytes
        self.maxStrippedSequenceBytes = maxStrippedSequenceBytes
    }

    func reset() {
        state = .normal
        buffer.removeAll(keepingCapacity: true)
        terminalStringSawEscape = false
        strippedSequenceBytes = 0
    }

    func filter(_ bytes: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        output.reserveCapacity(bytes.count)

        for byte in bytes {
            switch state {
            case .normal:
                switch byte {
                case 0x1b:
                    state = .escape
                    buffer = [byte]
                case 0x9d:
                    beginDetectingTerminalString(.osc, prefix: [byte])
                case 0x9f:
                    beginDetectingTerminalString(.apc, prefix: [byte])
                case 0x90:
                    beginDetectingTerminalString(.dcs, prefix: [byte])
                default:
                    output.append(byte)
                }

            case .escape:
                switch byte {
                case 0x5d:
                    beginDetectingTerminalString(.osc, prefix: [0x1b, byte])
                case 0x5f:
                    beginDetectingTerminalString(.apc, prefix: [0x1b, byte])
                case 0x50:
                    beginDetectingTerminalString(.dcs, prefix: [0x1b, byte])
                case 0x1b:
                    output.append(0x1b)
                    buffer = [0x1b]
                default:
                    output.append(contentsOf: buffer)
                    output.append(byte)
                    reset()
                }

            case .detectingTerminalString(let kind):
                appendDetectingTerminalStringByte(byte, kind: kind, output: &output)

            case .strippingTerminalString(let kind):
                appendStrippingTerminalStringByte(byte, kind: kind)

            case .passingThroughTerminalString(let kind):
                appendPassingThroughTerminalStringByte(byte, kind: kind, output: &output)
            }
        }

        return output
    }

    private func beginDetectingTerminalString(_ kind: SequenceKind, prefix: [UInt8]) {
        state = .detectingTerminalString(kind)
        buffer = prefix
        terminalStringSawEscape = false
        strippedSequenceBytes = 0
    }

    private func appendDetectingTerminalStringByte(_ byte: UInt8, kind: SequenceKind, output: inout [UInt8]) {
        buffer.append(byte)

        if consumesTerminalStringTerminator(byte) {
            finishDetectedTerminalString(kind, output: &output)
            return
        }

        switch detectionDecision(kind: kind, buffer: buffer) {
        case .wait:
            if buffer.count > maxDetectionBytes {
                output.append(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                state = .passingThroughTerminalString(kind)
            }

        case .strip:
            strippedSequenceBytes = buffer.count
            buffer.removeAll(keepingCapacity: true)
            state = .strippingTerminalString(kind)

        case .passThrough:
            output.append(contentsOf: buffer)
            buffer.removeAll(keepingCapacity: true)
            state = .passingThroughTerminalString(kind)
        }
    }

    private func appendStrippingTerminalStringByte(_ byte: UInt8, kind: SequenceKind) {
        strippedSequenceBytes += 1
        if consumesTerminalStringTerminator(byte) {
            reset()
            return
        }

        if strippedSequenceBytes > maxStrippedSequenceBytes {
            reset()
        }
    }

    private func appendPassingThroughTerminalStringByte(_ byte: UInt8, kind: SequenceKind, output: inout [UInt8]) {
        output.append(byte)
        if consumesTerminalStringTerminator(byte) {
            reset()
        }
    }

    private func finishDetectedTerminalString(_ kind: SequenceKind, output: inout [UInt8]) {
        if detectionDecision(kind: kind, buffer: buffer) != .strip {
            output.append(contentsOf: buffer)
        }
        reset()
    }

    private func consumesTerminalStringTerminator(_ byte: UInt8) -> Bool {
        if terminalStringSawEscape {
            defer {
                terminalStringSawEscape = false
            }
            return byte == 0x5c
        }

        if byte == 0x1b {
            terminalStringSawEscape = true
            return false
        }

        if byte == 0x9c || byte == 0x07 {
            return true
        }

        terminalStringSawEscape = false
        return false
    }

    private func detectionDecision(kind: SequenceKind, buffer: [UInt8]) -> DetectionDecision {
        let payload = payload(in: buffer)
        switch kind {
        case .osc:
            let inlineImagePrefix = Array("1337;File=".utf8)
            if payload.starts(with: inlineImagePrefix) {
                return .strip
            }
            if inlineImagePrefix.starts(with: payload) {
                return .wait
            }
            return .passThrough

        case .apc:
            guard let firstPayloadByte = payload.first else { return .wait }
            return firstPayloadByte == UInt8(ascii: "G") ? .strip : .passThrough

        case .dcs:
            guard let command = dcsCommand(in: payload) else { return .wait }
            return command.collect.isEmpty && command.final == UInt8(ascii: "q") ? .strip : .passThrough
        }
    }

    private func dcsCommand(in payload: ArraySlice<UInt8>) -> (collect: [UInt8], final: UInt8)? {
        var collect: [UInt8] = []
        var hasIntermediate = false

        for byte in payload {
            switch byte {
            case 0x30...0x3f where !hasIntermediate:
                continue
            case 0x20...0x2f:
                hasIntermediate = true
                collect.append(byte)
            case 0x40...0x7e:
                return (collect, byte)
            default:
                return nil
            }
        }

        return nil
    }

    private func payload(in buffer: [UInt8]) -> ArraySlice<UInt8> {
        let lowerBound = buffer.first == 0x1b ? min(2, buffer.count) : min(1, buffer.count)
        var upperBound = buffer.count

        if upperBound > lowerBound {
            let lastByte = buffer[upperBound - 1]
            if lastByte == 0x07 || lastByte == 0x9c {
                upperBound -= 1
            }
        }

        if upperBound - lowerBound >= 2,
           buffer[upperBound - 2] == 0x1b,
           buffer[upperBound - 1] == 0x5c {
            upperBound -= 2
        }

        return buffer[lowerBound..<max(lowerBound, upperBound)]
    }
}

enum TerminalResponseFilter {
    static func removingKittyGraphicsResponses(from bytes: ArraySlice<UInt8>) -> [UInt8] {
        let input = Array(bytes)
        var output: [UInt8] = []
        output.reserveCapacity(input.count)

        var index = 0
        while index < input.count {
            if let end = kittyGraphicsResponseEnd(in: input, at: index) {
                index = end
                continue
            }

            output.append(input[index])
            index += 1
        }

        return output
    }

    private static func kittyGraphicsResponseEnd(in input: [UInt8], at index: Int) -> Int? {
        if index + 2 < input.count,
           input[index] == 0x1b,
           input[index + 1] == 0x5f,
           input[index + 2] == UInt8(ascii: "G") {
            return terminalStringEnd(in: input, from: index + 3)
        }

        if index + 1 < input.count,
           input[index] == 0x9f,
           input[index + 1] == UInt8(ascii: "G") {
            return terminalStringEnd(in: input, from: index + 2)
        }

        return nil
    }

    private static func terminalStringEnd(in input: [UInt8], from start: Int) -> Int? {
        var sawEscape = false
        for index in start..<input.count {
            let byte = input[index]

            if sawEscape {
                if byte == 0x5c {
                    return index + 1
                }
                sawEscape = byte == 0x1b
                continue
            }

            if byte == 0x1b {
                sawEscape = true
                continue
            }

            if byte == 0x9c || byte == 0x07 {
                return index + 1
            }
        }

        return nil
    }
}
