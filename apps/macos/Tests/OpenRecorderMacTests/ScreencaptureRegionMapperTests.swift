import CoreGraphics
import XCTest
@testable import OpenRecorderMac

final class ScreencaptureRegionMapperTests: XCTestCase {
    func testMapsPrimaryDisplayCocoaAreaToScreencaptureCoordinates() {
        let area = CaptureArea(x: 420, y: 560, width: 460, height: 300, displayID: 2)
        let mapped = ScreencaptureRegionMapper.screencaptureArea(
            from: area,
            primaryDisplayFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )

        XCTAssertEqual(mapped, CaptureArea(x: 420, y: 220, width: 460, height: 300, displayID: 2))
    }

    func testMapsDisplayAbovePrimaryToNegativeScreencaptureY() {
        let area = CaptureArea(x: -1329, y: 1461, width: 647, height: 422, displayID: 4)
        let mapped = ScreencaptureRegionMapper.screencaptureArea(
            from: area,
            primaryDisplayFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )

        XCTAssertEqual(mapped, CaptureArea(x: -1329, y: -803, width: 647, height: 422, displayID: 4))
    }
}
