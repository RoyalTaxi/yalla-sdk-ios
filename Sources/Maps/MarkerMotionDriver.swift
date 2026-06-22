import UIKit
import YallaComponents

final class MarkerMotionDriver: NSObject {

    private var models: [String: DriverMotionModel] = [:]
    private var displayLink: CADisplayLink?
    private let onFrame: ([String: Pose]) -> Void

    private var lastEmitted: [String: Pose] = [:]

    private var cleared = false

    init(onFrame: @escaping ([String: Pose]) -> Void) {
        self.onFrame = onFrame
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
            if let last = lastEmitted[id], MarkerMotionDriver.posesClose(last, pose) { continue }
            lastEmitted[id] = pose
            poses[id] = pose
        }
        if !poses.isEmpty { onFrame(poses) }
    }

    static let positionEpsilonDegrees = 1e-6
    static let bearingEpsilonDegrees = 0.1

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
