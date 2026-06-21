import Foundation
import XCTest
@testable import Bridges

/// Pins the `onMain` helper that single-sources the bridge's "native renderers run on main" invariant
/// (review M1). On main it must run inline (no frame deferral); off main it must hop to main.
final class MainThreadTests: XCTestCase {
    func testRunsInlineWhenAlreadyOnMain() {
        var ran = false
        onMain {
            // Must execute synchronously, before onMain returns, while on the main thread.
            XCTAssertTrue(Thread.isMainThread)
            ran = true
        }
        XCTAssertTrue(ran, "onMain should run synchronously when called on the main thread")
    }

    func testHopsToMainWhenOffMain() {
        let onMainExpectation = expectation(description: "work runs on main")
        DispatchQueue.global().async {
            onMain {
                XCTAssertTrue(Thread.isMainThread)
                onMainExpectation.fulfill()
            }
        }
        wait(for: [onMainExpectation], timeout: 1)
    }
}
