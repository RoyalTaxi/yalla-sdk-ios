import XCTest
import YallaComponents
@testable import Maps

/// Pins the `fitBounds` absent-sentinel predicate (review #5). The renderers drop the `GeoPoint.Zero`
/// "no fix yet" sentinel before fitting bounds; the predicate must KEEP legitimate equator and
/// prime-meridian fixes and drop ONLY exact (0, 0). Guards against a regression to a naive
/// `lat == 0 && lng == 0` per-axis filter that would silently swallow real (0, lng)/(lat, 0) points.
final class GeoPointValidityTests: XCTestCase {

    func testExactZeroIsTreatedAsAbsent() {
        XCTAssertFalse(GeoPoint(lat: 0, lng: 0).hasFix)
    }

    func testEquatorPointIsKept() {
        // (0, lng): on the equator but a real fix — must NOT be filtered out.
        XCTAssertTrue(GeoPoint(lat: 0, lng: 69.24).hasFix)
    }

    func testPrimeMeridianPointIsKept() {
        // (lat, 0): on the prime meridian but a real fix — must NOT be filtered out.
        XCTAssertTrue(GeoPoint(lat: 41.31, lng: 0).hasFix)
    }

    func testTashkentPointIsKept() {
        XCTAssertTrue(GeoPoint(lat: 41.2995, lng: 69.2401).hasFix)
    }
}
