import YallaComponents

/// Single owner of the marker-to-route binding policy that was duplicated ~byte-for-byte across
/// both iOS renderers (`followedRouteId(for:)` / `applyFollowedRoute` / `reseedFollowedRoutes`
/// plus the `routeBindings` / `followedRouteByMarker` / `seededRoutePoints` state).
///
/// This is the iOS mirror of the Android `RouteFollowBinder`: pure binding policy with zero
/// backend specificity — it only touches marker ids, the binding map, the seed cache, and the
/// shared `MarkerMotionDriver`. Centralizing it kills the silent-divergence fragility where a
/// follow-route fix landed in one renderer and quietly persisted as a bug in the other.
///
/// It owns no route geometry math (it forwards already-resolved points to the motion model), so
/// the Humble-Object renderer-purity invariant (ADR 0003) is preserved.
final class FollowedRouteCoordinator {
    private let motion: MarkerMotionDriver
    /// Resolves points for `applyFollow`: rendered route first, then pending (a marker can start
    /// following before its route has been committed to the rendered store).
    private let routePoints: (_ routeId: String) -> [GeoPoint]?
    /// Resolves points for `reseedFollowedRoutes`: rendered routes only, matching the original
    /// reseed which read `routeData[routeId]` and skipped (`continue`) when absent.
    private let renderedRoutePoints: (_ routeId: String) -> [GeoPoint]?

    private var routeBindings: [String: String] = [:]
    private var followedRouteByMarker: [String: String] = [:]
    private var seededRoutePoints: [String: [GeoPoint]] = [:]

    init(
        motion: MarkerMotionDriver,
        routePoints: @escaping (_ routeId: String) -> [GeoPoint]?,
        renderedRoutePoints: @escaping (_ routeId: String) -> [GeoPoint]?
    ) {
        self.motion = motion
        self.routePoints = routePoints
        self.renderedRoutePoints = renderedRoutePoints
    }

    /// Stores a new binding map; returns true if it changed so the caller can re-apply follows
    /// behind its own backend-liveness guard. Mirrors the old `setRouteBindings` early-return.
    func updateBindings(_ bindings: [String: String]) -> Bool {
        guard routeBindings != bindings else { return false }
        routeBindings = bindings
        return true
    }

    /// The route a marker currently follows in the model (nil if none). Used by the renderer to
    /// route the trimmed-remaining-route writes to the right line.
    func routeId(forMarker markerId: String) -> String? {
        followedRouteByMarker[markerId]
    }

    /// Glues a flat marker to the route it follows, or detaches it when the binding (or the route's
    /// geometry) is gone/changed. Re-seeds the motion model only when the followed geometry changed
    /// (setRoute re-projects, so the car does not jump on a refetched route).
    func applyFollow(marker: MapMarker) {
        let markerId = marker.id
        guard let routeId = followedRouteId(for: marker),
              let points = routePoints(routeId) else {
            if followedRouteByMarker.removeValue(forKey: markerId) != nil {
                seededRoutePoints.removeValue(forKey: markerId)
                motion.setRoute(id: markerId, route: nil)
            }
            return
        }
        followedRouteByMarker[markerId] = routeId
        if !MapUtil.pointsEqual(seededRoutePoints[markerId], points) {
            seededRoutePoints[markerId] = points
            motion.setRoute(id: markerId, route: points)
        }
    }

    /// Re-seeds the motion model for any flat marker whose followed route geometry changed since it
    /// was last seeded — so a route refetch that arrives without a marker update still trims the
    /// right polyline.
    func reseedFollowedRoutes() {
        for (markerId, routeId) in followedRouteByMarker {
            guard let points = renderedRoutePoints(routeId) else { continue }
            if !MapUtil.pointsEqual(seededRoutePoints[markerId], points) {
                seededRoutePoints[markerId] = points
                motion.setRoute(id: markerId, route: points)
            }
        }
    }

    /// Forget a removed marker's follow state (called from the marker diff's stale-removal branch).
    /// Returns true if the marker had been following a route, so the caller can decide whether to
    /// also clear the marker from the motion model (Libre does; Google does not).
    @discardableResult
    func removeMarker(_ markerId: String) -> Bool {
        let wasFollowing = followedRouteByMarker.removeValue(forKey: markerId) != nil
        seededRoutePoints.removeValue(forKey: markerId)
        return wasFollowing
    }

    /// Clear all follow state (teardown / style swap).
    func clear() {
        followedRouteByMarker.removeAll()
        seededRoutePoints.removeAll()
    }

    /// Resolves the route a marker follows: a binding entry wins over the deprecated
    /// `MapMarker.followsRouteId` fallback.
    private func followedRouteId(for marker: MapMarker) -> String? {
        routeBindings[marker.id] ?? marker.followsRouteId
    }
}
