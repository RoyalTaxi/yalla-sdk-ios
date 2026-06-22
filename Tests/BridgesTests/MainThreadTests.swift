import Foundation
import XCTest
@testable import Bridges

final class MainThreadTests: XCTestCase {
    func testRunsInlineWhenAlreadyOnMain() {
        var ran = false
        onMain {
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
