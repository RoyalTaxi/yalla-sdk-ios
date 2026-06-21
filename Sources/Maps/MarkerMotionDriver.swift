import UIKit
import YallaComponents

final class MarkerMotionDriver: NSObject {

    private var models: [String: DriverMotionModel] = [:]
    private var displayLink: CADisplayLink?
    private let onFrame: ([String: Pose]) -> Void

    // Last pose emitted per id. A parked car samples the same pose every frame; skipping those
    // keeps the renderers from re-placing static map markers 30x/second (battery/jank on the
    // long "waiting for driver" wait). The display link keeps ticking (cheap sample) until a
    // settled-signal lands on DriverMotionModel; the expensive marker writes are what we cut.
    private var lastEmitted: [String: Pose] = [:]

    // Set by clear() and reset by push(): with no model and no fresh push since the last clear, an
    // ensureRunning() (e.g. a stray render after close()) must not resurrect the 30fps link. A real
    // push() — the legitimate reuse path, including the Libre style-reload that clear()s then re-adds
    // markers — re-arms the driver.
    private var cleared = false

    init(onFrame: @escaping ([String: Pose]) -> Void) {
        self.onFrame = onFrame
        super.init()
    }

    // Safety net behind close()→clear(). Because the link targets a weak proxy (below) rather than
    // self, ARC can reclaim the driver as soon as its renderer drops it even if close() was missed;
    // deinit then invalidates the still-live link so a zombie 30fps tick can't outlive the driver.
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

    func retain(ids: Set<String>) {
        let stale = Set(models.keys).subtracting(ids)
        for id in stale {
            models.removeValue(forKey: id)
            lastEmitted.removeValue(forKey: id)
        }
        if models.isEmpty { stop() }
    }

    func ensureRunning() {
        guard !cleared, displayLink == nil, !models.isEmpty else { return }
        // Target a weak proxy, NOT self: CADisplayLink retains its target, so targeting self would
        // keep the driver (and its renderer, via onFrame) alive until invalidate() runs — a leak +
        // a zombie 30fps tick if close() is ever missed. The proxy holds the driver weakly, so ARC
        // reclaims the driver when its renderer drops it; deinit then invalidates the link.
        let link = CADisplayLink(target: WeakDisplayLinkProxy(self), selector: #selector(WeakDisplayLinkProxy.onTick(_:)))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func clear() {
        cleared = true
        models.removeAll()
        lastEmitted.removeAll()
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
            // Emit only when the pose actually moved past the renderers' write epsilon.
            if let last = lastEmitted[id], MarkerMotionDriver.posesClose(last, pose) { continue }
            lastEmitted[id] = pose
            poses[id] = pose
        }
        if !poses.isEmpty { onFrame(poses) }
    }

    /// Two positions closer than this (~0.1m) are visually identical on the map.
    static let positionEpsilonDegrees = 1e-6
    /// Two bearings closer than this (degrees) are visually identical.
    static let bearingEpsilonDegrees = 0.1

    /// Positions within ~1e-6° (~0.1m) and bearings within 0.1° are visually identical — treat
    /// them as unchanged so a settled car doesn't trigger a marker rewrite every frame.
    /// `internal` (not `private`) so the per-frame emit-dedup boundary can be pinned by tests.
    static func posesClose(_ a: Pose, _ b: Pose) -> Bool {
        abs(a.point.lat - b.point.lat) < positionEpsilonDegrees &&
            abs(a.point.lng - b.point.lng) < positionEpsilonDegrees &&
            abs(Double(a.bearing) - Double(b.bearing)) < bearingEpsilonDegrees
    }

    private func makeModel() -> DriverMotionModel {
        return DriverMotionModel.companion.withDefaults()
    }

    private static func nowMillis() -> Int64 {
        return Int64(CACurrentMediaTime() * 1000.0)
    }
}

/// Forwards CADisplayLink ticks to the driver WITHOUT retaining it. CADisplayLink retains its target;
/// targeting the driver directly creates a link <-> driver cycle broken only by invalidate(). By
/// targeting this proxy (which holds the driver weakly) the link never keeps the driver alive, so ARC
/// reclaims the driver when its renderer drops it — even if close() is missed — and MarkerMotionDriver's
/// deinit then invalidates the orphaned link.
private final class WeakDisplayLinkProxy: NSObject {
    private weak var driver: MarkerMotionDriver?

    init(_ driver: MarkerMotionDriver) {
        self.driver = driver
        super.init()
    }

    @objc func onTick(_ link: CADisplayLink) {
        guard let driver = driver else {
            // Driver was deallocated without invalidating the link (e.g. close() missed). Stop here so
            // the orphaned proxy+link don't keep firing forever on the main runloop.
            link.invalidate()
            return
        }
        driver.tick(link)
    }
}
