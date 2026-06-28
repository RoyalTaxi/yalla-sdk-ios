import XCTest
import YallaComponents
@testable import Maps

final class FollowedRouteCoordinatorTests: XCTestCase {

    private func makeMotion() -> MarkerMotionDriver {
        // ChordOnly keeps setRoute a no-op; we only assert the coordinator's own state machine.
        MarkerMotionDriver(mode: MotionMode.ChordOnly.shared, onFrame: { _ in })
    }

    private func point(_ lat: Double, _ lng: Double) -> GeoPoint {
        GeoPoint(lat: lat, lng: lng)
    }

    private func marker(id: String, follows: String?) -> MapMarker {
        MapMarker(
            id: id,
            point: point(41.3, 69.2),
            icon: nil,
            rotation: 0,
            routeHeading: nil,
            anchor: Anchor(x: 0.5, y: 0.5),
            flat: true,
            zIndex: 0,
            contentDescription: nil,
            followsRouteId: follows
        )
    }

    func testUpdateBindingsReportsChangeOnce() {
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in nil }, renderedRoutePoints: { _ in nil })
        XCTAssertTrue(coordinator.updateBindings(["m": "r1"]))
        XCTAssertFalse(coordinator.updateBindings(["m": "r1"]), "same bindings must not report a change")
        XCTAssertTrue(coordinator.updateBindings(["m": "r2"]))
    }

    func testApplyFollowTracksRouteId() {
        let routePts = [point(41.0, 69.0), point(41.1, 69.1)]
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in routePts }, renderedRoutePoints: { _ in routePts })
        coordinator.applyFollow(marker: marker(id: "car", follows: "route1"))
        XCTAssertEqual(coordinator.routeId(forMarker: "car"), "route1")
    }

    func testBindingWinsOverFollowsRouteIdField() {
        let routePts = [point(41.0, 69.0), point(41.1, 69.1)]
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in routePts }, renderedRoutePoints: { _ in routePts })
        _ = coordinator.updateBindings(["car": "bound"])
        coordinator.applyFollow(marker: marker(id: "car", follows: "field"))
        XCTAssertEqual(coordinator.routeId(forMarker: "car"), "bound", "binding entry must win over followsRouteId")
    }

    func testApplyFollowWithoutRoutePointsDoesNotTrack() {
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in nil }, renderedRoutePoints: { _ in nil })
        coordinator.applyFollow(marker: marker(id: "car", follows: "missing"))
        XCTAssertNil(coordinator.routeId(forMarker: "car"))
    }

    func testRemoveMarkerReturnsWhetherFollowing() {
        let routePts = [point(41.0, 69.0), point(41.1, 69.1)]
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in routePts }, renderedRoutePoints: { _ in routePts })
        coordinator.applyFollow(marker: marker(id: "car", follows: "route1"))
        XCTAssertTrue(coordinator.removeMarker("car"), "a following marker reports true on removal")
        XCTAssertNil(coordinator.routeId(forMarker: "car"))
        XCTAssertFalse(coordinator.removeMarker("car"), "a non-following marker reports false")
    }

    func testClearForgetsAllFollowState() {
        let routePts = [point(41.0, 69.0), point(41.1, 69.1)]
        let coordinator = FollowedRouteCoordinator(motion: makeMotion(), routePoints: { _ in routePts }, renderedRoutePoints: { _ in routePts })
        coordinator.applyFollow(marker: marker(id: "car", follows: "route1"))
        coordinator.clear()
        XCTAssertNil(coordinator.routeId(forMarker: "car"))
    }
}
