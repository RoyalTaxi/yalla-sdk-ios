import UIKit
import YallaComponents

final class MarkerMotionDriver: NSObject {

    private var models: [String: DriverMotionModel] = [:]
    private var displayLink: CADisplayLink?
    private let onFrame: ([String: Pose]) -> Void
    private let onRoute: ((String, [GeoPoint]) -> Void)?
    private let onConnector: ((String, RouteConnector?) -> Void)?

    /// Derived from the required ``MotionMode`` passed at init. While `false` every model is a pure
    /// chord interpolator and ``setRoute(id:route:)`` is a no-op (the underlying `DriverMotionModel`
    /// also enforces this: with `routeFollowingEnabled = false`, `setRoute` is a no-op). The mode is
    /// a required init parameter — the renderer call site must choose ``MotionMode/RouteFollowing`` to
    /// opt a build into route-following. Making it required (no default) is what pins the production
    /// opt-in at the type level; it regressed to OFF twice when it was a defaulted boolean.
    private let routeFollowingEnabled: Bool

    private var lastEmitted: [String: Pose] = [:]
    private var lastEmittedRoute: [String: [GeoPoint]] = [:]
    private var lastEmittedConnector: [String: RouteConnector?] = [:]

    private var cleared = false

    /// - Parameters:
    ///   - mode: required motion mode. ``MotionMode/RouteFollowing`` opts every model into
    ///     route-eating; ``MotionMode/ChordOnly`` keeps every model a chord interpolator and makes
    ///     ``setRoute(id:route:)`` a no-op. There is no default — the call site must choose.
    ///   - onFrame: per-tick pose updates for moving markers.
    ///   - onRoute: per-tick *remaining* route for markers that are following a route (set via
    ///     ``setRoute(id:route:)``). Throttled the same way Android trims its eaten polyline —
    ///     only emitted when the head moved more than ``routeHeadEpsilonMeters`` or the vertex
    ///     count changed — so the renderer can shrink the drawn polyline in step with the car.
    ///   - onConnector: per-tick honesty connector (raw GPS → snapped point) for a route-following
    ///     marker, or `nil` when the raw fix sits on the line / the marker is off-route-and-chord.
    ///     The renderer draws this short line verbatim so a snap is never a silent lie. Emitted only
    ///     when it meaningfully changes (endpoint moved past ``routeHeadEpsilonMeters`` or the
    ///     visible/hidden state flipped).
    init(
        mode: MotionMode,
        onFrame: @escaping ([String: Pose]) -> Void,
        onRoute: ((String, [GeoPoint]) -> Void)? = nil,
        onConnector: ((String, RouteConnector?) -> Void)? = nil
    ) {
        self.routeFollowingEnabled = mode is MotionModeRouteFollowing
        self.onFrame = onFrame
        self.onRoute = onRoute
        self.onConnector = onConnector
        super.init()
    }

    deinit {
        stop()
    }

    func push(id: String, point: GeoPoint, routeHeading: Float?, serverHeading: Float) {
        cleared = false
        let model = models[id] ?? makeModel()
        models[id] = model
        model.push(
            point: point,
            routeHint: routeHeading.map { KotlinFloat(float: $0) },
            serverHeading: KotlinFloat(float: serverHeading),
            atMillis: MarkerMotionDriver.nowMillis()
        )
    }

    /// Switches the model for `id` into (or out of) route-following mode.
    ///
    /// Passing a non-nil `route` glues the marker to that polyline's arc-length progress so it
    /// rounds corners with the drawn route instead of cutting straight across. Passing `nil`
    /// reverts to chord interpolation. The model must already exist (created by a prior
    /// ``push(id:point:routeHeading:serverHeading:)``); calling before the first fix is a no-op
    /// so the route does not seed a model that has no displayed point yet.
    ///
    /// Gated behind ``routeFollowingEnabled``: while the flag is off this is a no-op so the marker
    /// stays a pure chord interpolator (the model itself also enforces this).
    func setRoute(id: String, route: [GeoPoint]?) {
        guard routeFollowingEnabled else { return }
        guard let model = models[id] else { return }
        model.setRoute(route: route)
        if route == nil {
            lastEmittedRoute.removeValue(forKey: id)
            if lastEmittedConnector[id] ?? nil != nil { onConnector?(id, nil) }
            lastEmittedConnector.removeValue(forKey: id)
        }
    }

    func retain(ids: Set<String>) {
        let stale = Set(models.keys).subtracting(ids)
        for id in stale {
            models.removeValue(forKey: id)
            lastEmitted.removeValue(forKey: id)
            lastEmittedRoute.removeValue(forKey: id)
            lastEmittedConnector.removeValue(forKey: id)
        }
        if models.isEmpty { stop() }
    }

    func ensureRunning() {
        guard !cleared, displayLink == nil, !models.isEmpty else { return }
        let link = CADisplayLink(target: WeakDisplayLinkProxy(self), selector: #selector(WeakDisplayLinkProxy.onTick(_:)))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func clear() {
        cleared = true
        models.removeAll()
        lastEmitted.removeAll()
        lastEmittedRoute.removeAll()
        lastEmittedConnector.removeAll()
        stop()
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc fileprivate func tick(_ link: CADisplayLink) {
        guard !models.isEmpty else { stop(); return }
        let now = MarkerMotionDriver.nowMillis()
        var poses: [String: Pose] = [:]
        poses.reserveCapacity(models.count)
        for (id, model) in models {
            let pose = model.sample(atMillis: now)
            if let last = lastEmitted[id], MarkerMotionDriver.posesClose(last, pose) {
                emitRouteIfChanged(id: id, model: model, now: now)
                emitConnectorIfChanged(id: id, model: model, now: now)
                continue
            }
            lastEmitted[id] = pose
            poses[id] = pose
            emitRouteIfChanged(id: id, model: model, now: now)
            emitConnectorIfChanged(id: id, model: model, now: now)
        }
        if !poses.isEmpty { onFrame(poses) }
    }

    /// Emits the trimmed remaining route for `id` when meaningfully changed. Mirrors Android's
    /// eaten-polyline throttle: only when the head vertex moved more than
    /// ``routeHeadEpsilonMeters`` or the vertex count changed, so we are not rebuilding the
    /// polyline geometry on every 30 Hz frame.
    private func emitRouteIfChanged(id: String, model: DriverMotionModel, now: Int64) {
        guard let onRoute = onRoute, model.isFollowingRoute() else { return }
        let remaining = model.remainingRoute(atMillis: now)
        let last = lastEmittedRoute[id]
        if let last = last, MarkerMotionDriver.routesClose(last, remaining) { return }
        lastEmittedRoute[id] = remaining
        onRoute(id, remaining)
    }

    /// Emits the honesty connector (raw GPS → snapped point) for `id` when it meaningfully changes.
    /// The model returns `nil` whenever the raw fix is essentially on the line, off-route (chord
    /// fallback), or not in route mode — in which case we emit a single `nil` so the renderer can
    /// tear the connector line down. Throttled like the eaten route: an endpoint moving less than
    /// ``routeHeadEpsilonMeters`` while staying visible is not re-emitted.
    private func emitConnectorIfChanged(id: String, model: DriverMotionModel, now: Int64) {
        guard let onConnector = onConnector, model.isFollowingRoute() else {
            if lastEmittedConnector[id] ?? nil != nil {
                lastEmittedConnector[id] = .some(nil)
                onConnector?(id, nil)
            }
            return
        }
        let connector = model.connector(atMillis: now)
        let previous = lastEmittedConnector[id] ?? nil
        if MarkerMotionDriver.connectorsClose(previous, connector) { return }
        lastEmittedConnector[id] = .some(connector)
        onConnector(id, connector)
    }

    static let positionEpsilonDegrees = 1e-6
    static let bearingEpsilonDegrees = 0.1
    /// ~3 m: same order as Android's route-trim throttle; below this the polyline visibly does
    /// not change, so re-pushing geometry would only churn the renderer.
    static let routeHeadEpsilonMeters = 3.0

    static func posesClose(_ a: Pose, _ b: Pose) -> Bool {
        abs(a.point.lat - b.point.lat) < positionEpsilonDegrees &&
            abs(a.point.lng - b.point.lng) < positionEpsilonDegrees &&
            abs(Double(a.bearing) - Double(b.bearing)) < bearingEpsilonDegrees
    }

    /// Two remaining-routes are "close" when they have the same vertex count and the head
    /// (the only end that moves as the car eats the route) is within ``routeHeadEpsilonMeters``.
    static func routesClose(_ a: [GeoPoint], _ b: [GeoPoint]) -> Bool {
        guard a.count == b.count else { return false }
        guard let ah = a.first, let bh = b.first else { return true }
        let metersPerDegLat = 111_320.0
        let metersPerDegLng = metersPerDegLat * cos(ah.lat * Double.pi / 180.0)
        let dLat = (ah.lat - bh.lat) * metersPerDegLat
        let dLng = (ah.lng - bh.lng) * metersPerDegLng
        return (dLat * dLat + dLng * dLng) < routeHeadEpsilonMeters * routeHeadEpsilonMeters
    }

    /// Two connectors are "close" when both are hidden, or both visible with each endpoint within
    /// ``routeHeadEpsilonMeters``. A flip between hidden and visible is never close (the renderer
    /// must add/remove the line). Mirrors the route-trim throttle so we are not rebuilding the
    /// connector geometry every 30 Hz frame.
    static func connectorsClose(_ a: RouteConnector?, _ b: RouteConnector?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (a?, b?):
            return metersBetween(a.rawPoint, b.rawPoint) < routeHeadEpsilonMeters &&
                metersBetween(a.snappedPoint, b.snappedPoint) < routeHeadEpsilonMeters
        default:
            return false
        }
    }

    private static func metersBetween(_ a: GeoPoint, _ b: GeoPoint) -> Double {
        let metersPerDegLat = 111_320.0
        let metersPerDegLng = metersPerDegLat * cos(a.lat * Double.pi / 180.0)
        let dLat = (a.lat - b.lat) * metersPerDegLat
        let dLng = (a.lng - b.lng) * metersPerDegLng
        return (dLat * dLat + dLng * dLng).squareRoot()
    }

    /// Builds a model honoring the feature flag: a chord interpolator by default (the production
    /// path), or a route-following model with default thresholds when the flag is on. Construction
    /// is the only place the flag is fixed on the model, so all models a driver owns share its mode.
    private func makeModel() -> DriverMotionModel {
        guard routeFollowingEnabled else {
            return DriverMotionModel.companion.withDefaults()
        }
        return DriverMotionModel(
            minMoveMeters: 1.5,
            teleportSpeedMps: 50.0,
            minDurationMs: 1_000,
            maxDurationMs: 12_000,
            defaultDurationMs: 10_000,
            routeFollowingEnabled: true,
            routeConfig: RouteFollowingConfig(
                routeArrivalThreshold: 25.0,
                connectorHideThreshold: 4.0,
                offRouteEnterMeters: 30.0,
                offRouteExitMeters: 15.0,
                backWindowMeters: 5.0,
                forwardWindowMeters: 50.0,
                maxHeadingTurnRatePerSecond: 120.0
            )
        )
    }

    private static func nowMillis() -> Int64 {
        return Int64(CACurrentMediaTime() * 1000.0)
    }
}

private final class WeakDisplayLinkProxy: NSObject {
    private weak var driver: MarkerMotionDriver?

    init(_ driver: MarkerMotionDriver) {
        self.driver = driver
        super.init()
    }

    @objc func onTick(_ link: CADisplayLink) {
        guard let driver = driver else {
            link.invalidate()
            return
        }
        driver.tick(link)
    }
}
