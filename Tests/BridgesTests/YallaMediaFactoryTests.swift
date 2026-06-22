import XCTest
@testable import Bridges

final class YallaMediaFactoryTests: XCTestCase {
    func testCaptureImageDeliversTerminalResultWhenCameraUnavailable() {
        let factory = YallaMediaFactory()
        let done = expectation(description: "onResult fires")
        var received: Data?? = nil
        factory.captureImage { data in
            received = .some(data)
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(received, .some(nil), "captureImage must complete with nil when the camera is unavailable")
    }

    func testCaptureImageResolvesEvenWithNoPresentableWindow() {
        let factory = YallaMediaFactory()
        let done = expectation(description: "onResult fires")
        factory.captureImage { _ in done.fulfill() }
        wait(for: [done], timeout: 2)
    }
}
