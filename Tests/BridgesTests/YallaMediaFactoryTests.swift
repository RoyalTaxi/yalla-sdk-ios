import XCTest
@testable import Bridges

/// Pins the media factory's "always completes" contract (review H3). The Kotlin caller is
/// fire-and-forget with no timeout, so `onResult` is the sole resumption path — every entry point
/// must resolve it exactly once, including on the failure paths that previously `return`ed silently.
final class YallaMediaFactoryTests: XCTestCase {
    func testCaptureImageDeliversTerminalResultWhenCameraUnavailable() {
        // The test host has no camera (`isSourceTypeAvailable(.camera) == false`), so capture must
        // resolve a terminal `nil` rather than presenting a dead picker and hanging.
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
        // With no key window / camera, capture must still complete — never strand the caller.
        let factory = YallaMediaFactory()
        let done = expectation(description: "onResult fires")
        factory.captureImage { _ in done.fulfill() }
        wait(for: [done], timeout: 2)
    }
}
