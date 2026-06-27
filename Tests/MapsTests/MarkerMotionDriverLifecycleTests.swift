import XCTest
import YallaComponents
@testable import Maps

@MainActor
final class MarkerMotionDriverLifecycleTests: XCTestCase {

    private func spinRunLoop(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    func testDriverEmitsWhileRunning() {
        var frames = 0
        let driver = MarkerMotionDriver(mode: MotionMode.ChordOnly.shared, onFrame: { _ in frames += 1 })
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.push(id: "car-1", point: GeoPoint(lat: 41.40, lng: 69.30), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.ensureRunning()
        spinRunLoop(0.2)
        XCTAssertGreaterThan(frames, 0, "a running driver with a moving model should emit at least one frame")
    }

    func testClearedDriverDoesNotResurrectWithoutFreshPush() {
        var frames = 0
        let driver = MarkerMotionDriver(mode: MotionMode.ChordOnly.shared, onFrame: { _ in frames += 1 })
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.push(id: "car-1", point: GeoPoint(lat: 41.40, lng: 69.30), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.clear()

        driver.ensureRunning()

        frames = 0
        spinRunLoop(0.2)
        XCTAssertEqual(frames, 0, "a cleared driver must stay inert until a fresh push() re-arms it")
    }

    func testReusedDriverRunsAgainAfterPush() {
        var frames = 0
        let driver = MarkerMotionDriver(mode: MotionMode.ChordOnly.shared, onFrame: { _ in frames += 1 })
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.clear()

        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.push(id: "car-1", point: GeoPoint(lat: 41.50, lng: 69.40), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.ensureRunning()

        frames = 0
        spinRunLoop(0.2)
        XCTAssertGreaterThan(frames, 0, "a fresh push() after clear() must re-arm the driver")
    }
}
