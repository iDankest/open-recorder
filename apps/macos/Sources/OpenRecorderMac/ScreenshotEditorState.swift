import Foundation
import SwiftUI

struct ScreenshotEditorState: Codable, Equatable, Hashable {
    var background: BackgroundStyle = BackgroundPresets.default
    var padding = 56.0
    var backgroundRoundness = 28.0
    var backgroundShadow = 0.0
    var imageRoundness = 10.0
    var imageShadow = 0.45

    static let `default` = ScreenshotEditorState()

    init(
        background: BackgroundStyle = BackgroundPresets.default,
        padding: Double = 56.0,
        backgroundRoundness: Double = 28.0,
        backgroundShadow: Double = 0.0,
        imageRoundness: Double = 10.0,
        imageShadow: Double = 0.45
    ) {
        self.background = background
        self.padding = padding
        self.backgroundRoundness = backgroundRoundness
        self.backgroundShadow = backgroundShadow
        self.imageRoundness = imageRoundness
        self.imageShadow = imageShadow
    }

    private enum CodingKeys: String, CodingKey {
        case background
        case padding
        case backgroundRoundness
        case backgroundShadow
        case imageRoundness
        case imageShadow
    }

    init(from decoder: Decoder) throws {
        let defaults = Self.default
        let container = try decoder.container(keyedBy: CodingKeys.self)
        background = try container.decodeIfPresent(BackgroundStyle.self, forKey: .background) ?? defaults.background
        padding = try container.decodeIfPresent(Double.self, forKey: .padding) ?? defaults.padding
        backgroundRoundness = try container.decodeIfPresent(Double.self, forKey: .backgroundRoundness) ?? defaults.backgroundRoundness
        backgroundShadow = try container.decodeIfPresent(Double.self, forKey: .backgroundShadow) ?? defaults.backgroundShadow
        imageRoundness = try container.decodeIfPresent(Double.self, forKey: .imageRoundness) ?? defaults.imageRoundness
        imageShadow = try container.decodeIfPresent(Double.self, forKey: .imageShadow) ?? defaults.imageShadow
    }
}

@MainActor
final class ScreenshotEditorController: ObservableObject {
    @Published private(set) var state = ScreenshotEditorState.default
    private var history = EditorHistory<ScreenshotEditorState>()

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }

    func undo() {
        guard let previous = history.undo(current: state) else { return }
        state = previous
    }

    func redo() {
        guard let next = history.redo(current: state) else { return }
        state = next
    }

    func resetHistory() {
        history.reset()
        objectWillChange.send()
    }

    func apply(_ nextState: ScreenshotEditorState) {
        state = nextState
        resetHistory()
    }

    func beginUndoTransaction() {
        history.beginTransaction(current: state)
    }

    func endUndoTransaction() {
        if history.commitTransaction(current: state) {
            objectWillChange.send()
        }
    }

    func update<Value: Equatable>(_ keyPath: WritableKeyPath<ScreenshotEditorState, Value>, to value: Value) {
        var next = state
        guard next[keyPath: keyPath] != value else { return }
        let before = state
        next[keyPath: keyPath] = value
        state = next
        history.recordChange(from: before, to: next)
    }

    func binding<Value: Equatable>(for keyPath: WritableKeyPath<ScreenshotEditorState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.update(keyPath, to: $0) }
        )
    }
}
