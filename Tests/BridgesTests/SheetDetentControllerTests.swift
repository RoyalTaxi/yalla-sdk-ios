import UIKit
import XCTest
@testable import Bridges

final class SheetDetentControllerTests: XCTestCase {
    private func makeController(sizesToContent: Bool = true) -> (SheetDetentController, () -> Int) {
        var invalidations = 0
        let controller = SheetDetentController(sizesToContent: sizesToContent) { _ in
            invalidations += 1
        }
        return (controller, { invalidations })
    }

    func testSeedSetsMeasuredHeightRounded() {
        let (controller, _) = makeController()
        controller.seedInitialHeight(123.4)
        XCTAssertEqual(controller.measuredHeight, 123)
    }

    func testSeedIgnoredWhenNotSizingToContent() {
        let (controller, _) = makeController(sizesToContent: false)
        controller.seedInitialHeight(200)
        XCTAssertNil(controller.measuredHeight)
    }

    func testLayoutHeightWithinEpsilonIsCoalesced() {
        let (controller, _) = makeController()
        controller.seedInitialHeight(100)
        controller.requestLayoutHeight(100.4) // < detentEpsilon (1)
        XCTAssertEqual(controller.measuredHeight, 100, "sub-epsilon change must not move measuredHeight")
    }

    func testLayoutHeightBeyondEpsilonUpdates() {
        let (controller, _) = makeController()
        controller.seedInitialHeight(100)
        controller.requestLayoutHeight(150)
        XCTAssertEqual(controller.measuredHeight, 150)
    }

    func testLayoutHeightIgnoredAfterContentReported() {
        let (controller, _) = makeController()
        controller.requestContentHeight(300) // marks hasReportedContentHeight
        controller.requestLayoutHeight(120)
        XCTAssertEqual(controller.measuredHeight, 300, "layout path must be inert once Compose has reported")
    }

    func testContentHeightSetsReportedFlag() {
        let (controller, _) = makeController()
        XCTAssertFalse(controller.hasReportedContentHeight)
        controller.requestContentHeight(250)
        XCTAssertTrue(controller.hasReportedContentHeight)
        XCTAssertEqual(controller.measuredHeight, 250)
    }

    func testContentHeightWithinEpsilonIsCoalesced() {
        let (controller, _) = makeController()
        controller.requestContentHeight(200)
        controller.requestContentHeight(200.5) // < detentEpsilon (1)
        XCTAssertEqual(controller.measuredHeight, 200)
    }

    func testResetClearsReportedFlag() {
        let (controller, _) = makeController()
        controller.requestContentHeight(200)
        controller.reset()
        XCTAssertFalse(controller.hasReportedContentHeight)
        // After reset, the layout path becomes live again.
        controller.requestLayoutHeight(180)
        XCTAssertEqual(controller.measuredHeight, 180)
    }

    func testInvalidationIsDispatchedOnMeaningfulChange() {
        let (controller, invalidations) = makeController()
        let expectation = expectation(description: "invalidate dispatched")
        controller.requestContentHeight(220)
        DispatchQueue.main.async {
            XCTAssertEqual(invalidations(), 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
