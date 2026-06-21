import XCTest
import YallaComponents
@testable import Maps

/// Pins the motion-driver lifecycle safety net (review H2 / #8). After `clear()` (reached from
/// `renderer.close()`) the driver must be inert: an `ensureRunning()` with no fresh `push()` since the
/// clear must NOT resurrect the 30fps `CADisplayLink`, so `onFrame` must never fire. A legitimate
/// `push()` (the reuse path, e.g. Libre style reload) re-arms it. Guards against a zombie timer that
/// keeps ticking on the main runloop after teardown, while preserving renderer reuse.
///
/// These run on the main thread (CADisplayLink requires a runloop); the driver is main-thread-only.
@MainActor
final class MarkerMotionDriverLifecycleTests: XCTestCase {

    private func spinRunLoop(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    func testDriverEmitsWhileRunning() {
        var frames = 0
        let driver = MarkerMotionDriver { _ in frames += 1 }
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        // Push a second, distinct sample so the model interpolates and the pose changes between frames.
        driver.push(id: "car-1", point: GeoPoint(lat: 41.40, lng: 69.30), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.ensureRunning()
        spinRunLoop(0.2)
        XCTAssertGreaterThan(frames, 0, "a running driver with a moving model should emit at least one frame")
    }

    func testClearedDriverDoesNotResurrectWithoutFreshPush() {
        var frames = 0
        let driver = MarkerMotionDriver { _ in frames += 1 }
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.push(id: "car-1", point: GeoPoint(lat: 41.40, lng: 69.30), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.clear()

        // A stray ensureRunning() after teardown, with no new push, must NOT restart the link.
        driver.ensureRunning()

        frames = 0
        spinRunLoop(0.2)
        XCTAssertEqual(frames, 0, "a cleared driver must stay inert until a fresh push() re-arms it")
    }

    func testReusedDriverRunsAgainAfterPush() {
        var frames = 0
        let driver = MarkerMotionDriver { _ in frames += 1 }
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.clear()

        // The legitimate reuse path (e.g. Libre style reload): clear() then re-add markers. The driver
        // must come back to life.
        driver.push(id: "car-1", point: GeoPoint(lat: 41.30, lng: 69.20), routeHeading: nil, serverHeading: 0)
        driver.push(id: "car-1", point: GeoPoint(lat: 41.50, lng: 69.40), routeHeading: nil, serverHeading: 0)
        driver.retain(ids: ["car-1"])
        driver.ensureRunning()

        frames = 0
        spinRunLoop(0.2)
        XCTAssertGreaterThan(frames, 0, "a fresh push() after clear() must re-arm the driver")
    }
}
