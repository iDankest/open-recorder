import Foundation

struct CaptureArea: Codable, Hashable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
}

enum CaptureSourceKind: String, Codable, CaseIterable, Identifiable {
    case display
    case window
    case area

    var id: String { rawValue }

    var label: String {
        switch self {
        case .display: "Display"
        case .window: "Window"
        case .area: "Area"
        }
    }
}

struct CaptureSource: Identifiable, Codable, Hashable {
    var id: String
    var kind: CaptureSourceKind
    var name: String
    var subtitle: String
    var displayIndex: Int?
    var displayID: UInt32?
    var windowID: UInt32?
    var area: CaptureArea?
    var thumbnailData: Data?
}

struct AppPaths: Codable, Equatable {
    var recordingsDir: String
    var screenshotsDir: String
    var projectsDir: String
    var supportDir: String
}

struct PreparedFile: Codable {
    var path: String
}

struct ProjectSummary: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var path: String
    var recordingPath: String?
    var sourceName: String?
    var createdAt: String
    var updatedAt: String
    var lastOpenedAt: String
    var missing: Bool
}

struct ProjectDocument: Codable {
    var schemaVersion: Int
    var title: String
    var recordingPath: String?
    var sourceName: String?
    var createdAt: String
    var updatedAt: String
}

enum EditorMediaKind: String, Codable, Hashable {
    case video
    case screenshot

    var badge: String {
        switch self {
        case .video: "MP4"
        case .screenshot: "PNG"
        }
    }
}

struct EditorSession: Codable, Hashable, Identifiable {
    var id: UUID
    var kind: EditorMediaKind
    var path: String
    var title: String

    init(kind: EditorMediaKind, url: URL, title: String? = nil, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.path = url.path
        self.title = title ?? url.lastPathComponent
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case capture
    case projects
    case editor
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .capture: "Capture"
        case .projects: "Projects"
        case .editor: "Editor"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .capture: "record.circle"
        case .projects: "folder"
        case .editor: "slider.horizontal.3"
        case .settings: "gearshape"
        }
    }
}

enum CaptureMode: String, CaseIterable, Identifiable {
    case recording
    case screenshot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recording: "Recording"
        case .screenshot: "Screenshot"
        }
    }
}

enum CaptureFlow: String, CaseIterable, Identifiable {
    case choice
    case screenshotSetup
    case recordingSetup
    case recording

    var id: String { rawValue }
}

enum NativeWindowCommandAction: Equatable {
    case showHUD
    case showSourceSelector
    case showAreaSelector
    case showStudio
    case closeSourceSelector
    case closeAreaSelector
}

struct NativeWindowCommand: Identifiable {
    var id = UUID()
    var action: NativeWindowCommandAction
    var editorSession: EditorSession?
}

struct HealthPayload: Codable {
    var service: String
    var version: String
    var platform: String
}

func timestampedFileName(prefix: String, extension fileExtension: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    return "\(prefix)-\(formatter.string(from: Date())).\(fileExtension)"
}
