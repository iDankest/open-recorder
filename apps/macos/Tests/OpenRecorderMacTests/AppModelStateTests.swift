import XCTest
@testable import OpenRecorderMac

@MainActor
final class AppModelStateTests: XCTestCase {
    func testBeginRecordingMovesToSetupAndRequestsSelector() {
        let model = AppModel()

        model.beginCapture(.recording)

        XCTAssertEqual(model.captureMode, .recording)
        XCTAssertEqual(model.captureFlow, .recordingSetup)
        XCTAssertEqual(model.windowCommand?.action, .showSourceSelector)
    }

    func testBeginScreenshotMovesToSetupAndRequestsSelector() {
        let model = AppModel()

        model.beginCapture(.screenshot)

        XCTAssertEqual(model.captureMode, .screenshot)
        XCTAssertEqual(model.captureFlow, .screenshotSetup)
        XCTAssertEqual(model.windowCommand?.action, .showSourceSelector)
    }

    func testNewCaptureIsDisabledOnlyWhileRecording() {
        let model = AppModel()

        XCTAssertTrue(model.canStartNewCapture)

        model.capture.setRecordingForTesting(true)

        XCTAssertFalse(model.canStartNewCapture)
    }

    func testShowEditorCarriesIndependentEditorSession() {
        let model = AppModel()
        let url = URL(fileURLWithPath: "/tmp/example-recording.mp4")
        let session = EditorSession(kind: .video, url: url, title: "Example Recording")

        model.showEditor(for: session)

        XCTAssertEqual(model.selectedSection, .editor)
        XCTAssertEqual(model.lastEditorSession, session)
        XCTAssertEqual(model.windowCommand?.action, .showStudio)
        XCTAssertEqual(model.windowCommand?.editorSession, session)
    }

    func testAreaSelectionUsesInteractiveAreaSource() {
        let model = AppModel()

        model.selectInteractiveAreaSource()

        XCTAssertEqual(model.selectedSource?.kind, .area)
        XCTAssertEqual(model.selectedSource?.id, "area:interactive")
        XCTAssertEqual(model.statusMessage, "Selected area")
    }

    func testWindowCommandIsConsumedOnce() {
        let model = AppModel()
        model.requestWindow(.showStudio)

        let firstCommand = model.consumeWindowCommand(model.windowCommand)
        let secondCommand = model.consumeWindowCommand(model.windowCommand)

        XCTAssertEqual(firstCommand?.action, .showStudio)
        XCTAssertNil(secondCommand)
    }
}
