import XCTest
import YallaComponents
@testable import Maps

/// Pins the per-frame emit-dedup boundary on the marker motion hot path (review #17). `posesClose`
/// gates every marker write: a settled car must be treated as unchanged (skip the rewrite), while a
/// move past the position/bearing epsilon must register. Guards the named thresholds against drift.
final class MarkerMotionDriverTests: XCTestCase {

    private func pose(lat: Double, lng: Double, bearing: Float) -> Pose {
        Pose(point: GeoPoint(lat: lat, lng: lng), bearing: bearing)
    }

    func testIdenticalPosesAreClose() {
        let a = pose(lat: 41.3, lng: 69.2, bearing: 90)
        XCTAssertTrue(MarkerMotionDriver.posesClose(a, a))
    }

    func testSubEpsilonPositionDriftIsClose() {
        let a = pose(lat: 41.3, lng: 69.2, bearing: 90)
        let b = pose(lat: 41.3 + MarkerMotionDriver.positionEpsilonDegrees / 2,
                     lng: 69.2,
                     bearing: 90)
        XCTAssertTrue(MarkerMotionDriver.posesClose(a, b))
    }

    func testOverEpsilonPositionDriftIsNotClose() {
        let a = pose(lat: 41.3, lng: 69.2, bearing: 90)
        let b = pose(lat: 41.3 + MarkerMotionDriver.positionEpsilonDegrees * 2,
                     lng: 69.2,
                     bearing: 90)
        XCTAssertFalse(MarkerMotionDriver.posesClose(a, b))
    }

    func testSubEpsilonBearingDriftIsClose() {
        let a = pose(lat: 41.3, lng: 69.2, bearing: 90)
        let b = pose(lat: 41.3, lng: 69.2, bearing: 90 + Float(MarkerMotionDriver.bearingEpsilonDegrees) / 2)
        XCTAssertTrue(MarkerMotionDriver.posesClose(a, b))
    }

    func testOverEpsilonBearingDriftIsNotClose() {
        let a = pose(lat: 41.3, lng: 69.2, bearing: 90)
        let b = pose(lat: 41.3, lng: 69.2, bearing: 90 + Float(MarkerMotionDriver.bearingEpsilonDegrees) * 2)
        XCTAssertFalse(MarkerMotionDriver.posesClose(a, b))
    }
}
