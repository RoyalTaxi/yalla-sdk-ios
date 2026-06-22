import XCTest
import YallaComponents
@testable import Maps

final class GeoPointValidityTests: XCTestCase {

    func testExactZeroIsTreatedAsAbsent() {
        XCTAssertFalse(GeoPoint(lat: 0, lng: 0).hasFix)
    }

    func testEquatorPointIsKept() {
        XCTAssertTrue(GeoPoint(lat: 0, lng: 69.24).hasFix)
    }

    func testPrimeMeridianPointIsKept() {
        XCTAssertTrue(GeoPoint(lat: 41.31, lng: 0).hasFix)
    }

    func testTashkentPointIsKept() {
        XCTAssertTrue(GeoPoint(lat: 41.2995, lng: 69.2401).hasFix)
    }
}
