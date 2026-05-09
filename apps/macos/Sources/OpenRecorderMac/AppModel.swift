import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedSection: AppSection = .capture
    @Published var captureMode: CaptureMode = .recording
    @Published var captureFlow: CaptureFlow = .choice
    @Published var selectedSource: CaptureSource?
    @Published var paths: AppPaths?
    @Published var projects: [ProjectSummary] = []
    @Published var currentVideoURL: URL?
    @Published var currentScreenshotURL: URL?
    @Published var lastEditorSession: EditorSession?
    @Published var statusMessage = "Ready"
    @Published var serviceHealth: HealthPayload?
    @Published var includeMicrophone = false
    @Published var showCursor = true
    @Published var showClicks = false
    @Published var windowCommand: NativeWindowCommand?
    @Published var isAreaSelectionActive = false

    private var handledWindowCommandID: UUID?

    let service = RustServiceClient()
    let capture = CaptureController()

    func bootstrap() {
        Task {
            await refreshSources()
        }
        refreshBackendState()
    }

    func refreshBackendState() {
        do {
            serviceHealth = try service.call("health", as: HealthPayload.self)
            paths = try service.call("paths", as: AppPaths.self)
            projects = try service.call("listProjects", as: [ProjectSummary].self)
            statusMessage = "Rust service ready"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func reloadSources() {
        Task {
            await refreshSources()
        }
    }

    func refreshSources() async {
        await capture.reloadSources()
        if selectedSource == nil || !capture.sources.contains(where: { $0.id == selectedSource?.id }) {
            selectedSource = capture.sources.first
        }
    }

    var canStartNewCapture: Bool {
        !capture.isRecording
    }

    func beginCapture(_ mode: CaptureMode) {
        guard canStartNewCapture else {
            statusMessage = "Stop the current recording before starting another capture."
            return
        }

        captureMode = mode
        captureFlow = mode == .screenshot ? .screenshotSetup : .recordingSetup
        statusMessage = selectedSource == nil ? "Choose a source." : "Ready"
        requestWindow(.showSourceSelector)
    }

    func selectSource(_ source: CaptureSource) {
        selectedSource = source
        statusMessage = "Selected \(source.name)"
    }

    func selectInteractiveAreaSource(area: CaptureArea? = nil) {
        selectedSource = CaptureSource(
            id: "area:interactive",
            kind: .area,
            name: "Selected Area",
            subtitle: area.map { "\($0.width) x \($0.height)" } ?? "Draw area when capture starts",
            displayIndex: nil,
            displayID: nil,
            windowID: nil,
            area: area,
            thumbnailData: nil
        )
        statusMessage = "Selected area"
    }

    func requestInteractiveAreaSelection() {
        selectInteractiveAreaSource()
        isAreaSelectionActive = true
        statusMessage = "Draw an area to capture."
        requestWindow(.showAreaSelector)
    }

    func completeInteractiveAreaSelection(_ area: CaptureArea) {
        isAreaSelectionActive = false
        selectInteractiveAreaSource(area: area)

        switch captureMode {
        case .recording:
            startRecording()
        case .screenshot:
            takeScreenshot()
        }
    }

    func cancelInteractiveAreaSelection() {
        isAreaSelectionActive = false
        requestWindow(.closeAreaSelector)
    }

    func requestWindow(_ action: NativeWindowCommandAction, editorSession: EditorSession? = nil) {
        windowCommand = NativeWindowCommand(action: action, editorSession: editorSession)
    }

    func showEditor(for session: EditorSession) {
        lastEditorSession = session
        selectedSection = .editor
        requestWindow(.showStudio, editorSession: session)
    }

    func consumeWindowCommand(_ command: NativeWindowCommand?) -> NativeWindowCommand? {
        guard let command, handledWindowCommandID != command.id else {
            return nil
        }
        handledWindowCommandID = command.id
        return command
    }

    func startRecording() {
        guard let selectedSource else {
            statusMessage = "Choose a source first."
            return
        }

        do {
            let fileName = timestampedFileName(prefix: "recording", extension: "mp4")
            let prepared: PreparedFile = try service.call(
                "prepareRecordingFile",
                params: ["fileName": fileName],
                as: PreparedFile.self
            )
            let outputURL = URL(fileURLWithPath: prepared.path)
            statusMessage = "Starting recording..."
            Task {
                do {
                    try await capture.startRecording(
                        source: selectedSource,
                        outputURL: outputURL,
                        includeMicrophone: includeMicrophone,
                        showCursor: showCursor,
                        showClicks: showClicks
                    )
                    currentVideoURL = outputURL
                    currentScreenshotURL = nil
                    captureFlow = .recording
                    statusMessage = "Recording \(selectedSource.name)"
                } catch {
                    statusMessage = error.localizedDescription
                }
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        Task {
            do {
                let outputURL = try await capture.stopRecording()
                currentVideoURL = outputURL
                currentScreenshotURL = nil

                if FileManager.default.fileExists(atPath: outputURL.path) {
                    let summary: ProjectSummary = try service.call(
                        "registerRecording",
                        params: [
                            "path": outputURL.path,
                            "sourceName": selectedSource?.name ?? "Screen Recording",
                            "title": outputURL.deletingPathExtension().lastPathComponent
                        ],
                        as: ProjectSummary.self
                    )
                    projects = try service.call("listProjects", as: [ProjectSummary].self)
                    captureFlow = .recordingSetup
                    showEditor(for: EditorSession(kind: .video, url: outputURL, title: summary.title))
                    statusMessage = "Saved \(summary.title)"
                } else {
                    statusMessage = "Recording stopped before a file was written."
                }
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    func takeScreenshot() {
        guard let selectedSource else {
            statusMessage = "Choose a source first."
            return
        }

        do {
            let ensuredPaths = try paths ?? service.call("paths", as: AppPaths.self)
            let outputURL = URL(fileURLWithPath: ensuredPaths.screenshotsDir)
                .appendingPathComponent(timestampedFileName(prefix: "screenshot", extension: "png"))
            try capture.takeScreenshot(source: selectedSource, outputURL: outputURL)
            let _: PreparedFile = try service.call(
                "rememberScreenshot",
                params: ["path": outputURL.path],
                as: PreparedFile.self
            )
            currentScreenshotURL = outputURL
            currentVideoURL = nil
            showEditor(for: EditorSession(kind: .screenshot, url: outputURL))
            statusMessage = "Captured \(outputURL.lastPathComponent)"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func openProject(_ project: ProjectSummary) {
        if let recordingPath = project.recordingPath {
            let recordingURL = URL(fileURLWithPath: recordingPath)
            currentVideoURL = recordingURL
            currentScreenshotURL = nil
            showEditor(for: EditorSession(kind: .video, url: recordingURL, title: project.title))
            statusMessage = "Opened \(project.title)"
        } else {
            statusMessage = "Project has no recording path."
        }
    }

    func openProjectFile() {
        let panel = NSOpenPanel()
        if let projectType = UTType(filenameExtension: "openrecorder") {
            panel.allowedContentTypes = [projectType]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let projectURL = panel.url else {
            return
        }

        openProjectFile(at: projectURL)
    }

    func openProjectFile(at projectURL: URL) {
        do {
            let document: ProjectDocument = try service.call(
                "loadProject",
                params: ["path": projectURL.path],
                as: ProjectDocument.self
            )
            if let recordingPath = document.recordingPath {
                let recordingURL = URL(fileURLWithPath: recordingPath)
                currentVideoURL = recordingURL
                currentScreenshotURL = nil
                showEditor(for: EditorSession(kind: .video, url: recordingURL, title: document.title))
                statusMessage = "Opened \(document.title)"
                refreshBackendState()
            } else {
                statusMessage = "Project has no recording path."
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func openPath(_ path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func copyScreenshotToClipboard(_ screenshotURL: URL? = nil) {
        guard let url = screenshotURL ?? currentScreenshotURL,
              let image = NSImage(contentsOf: url) else {
            statusMessage = "No screenshot to copy."
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        statusMessage = "Screenshot copied"
    }

    func exportCurrentRecording(_ recordingURL: URL? = nil) {
        guard let url = recordingURL ?? currentVideoURL else {
            statusMessage = "Open a recording first."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        panel.nameFieldStringValue = url.lastPathComponent
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return
        }

        do {
            let exported: PreparedFile = try service.call(
                "exportRecording",
                params: [
                    "sourcePath": url.path,
                    "targetPath": targetURL.path
                ],
                as: PreparedFile.self
            )
            statusMessage = "Exported \(URL(fileURLWithPath: exported.path).lastPathComponent)"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func openPrivacySettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}
