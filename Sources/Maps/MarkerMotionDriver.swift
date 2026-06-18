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

    init(onFrame: @escaping ([String: Pose]) -> Void) {
        self.onFrame = onFrame
        super.init()
    }

    func push(id: String, point: GeoPoint, routeHeading: Float?, serverHeading: Float) {
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
        guard displayLink == nil, !models.isEmpty else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func clear() {
        models.removeAll()
        lastEmitted.removeAll()
        stop()
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
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

    /// Positions within ~1e-6° (~0.1m) and bearings within 0.1° are visually identical — treat
    /// them as unchanged so a settled car doesn't trigger a marker rewrite every frame.
    private static func posesClose(_ a: Pose, _ b: Pose) -> Bool {
        abs(a.point.lat - b.point.lat) < 1e-6 &&
            abs(a.point.lng - b.point.lng) < 1e-6 &&
            abs(Double(a.bearing) - Double(b.bearing)) < 0.1
    }

    private func makeModel() -> DriverMotionModel {
        return DriverMotionModel.companion.withDefaults()
    }

    private static func nowMillis() -> Int64 {
        return Int64(CACurrentMediaTime() * 1000.0)
    }
}
