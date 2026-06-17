import UIKit
import YallaComponents

final class MarkerMotionDriver {

    private var models: [String: DriverMotionModel] = [:]
    private var displayLink: CADisplayLink?
    private let onFrame: ([String: Pose]) -> Void

    init(onFrame: @escaping ([String: Pose]) -> Void) {
        self.onFrame = onFrame
    }

    func push(id: String, point: GeoPoint, heading: Float) {
        let model = models[id] ?? makeModel()
        models[id] = model
        model.push(point: point, serverHeading: heading, atMillis: MarkerMotionDriver.nowMillis())
    }

    func retain(ids: Set<String>) {
        let stale = Set(models.keys).subtracting(ids)
        for id in stale { models.removeValue(forKey: id) }
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
        for (id, model) in models { poses[id] = model.sample(atMillis: now) }
        onFrame(poses)
    }

    private func makeModel() -> DriverMotionModel {
        return DriverMotionModel(
            minMoveMeters: 1.5,
            teleportSpeedMps: 50.0,
            minDurationMs: 1000,
            maxDurationMs: 12000,
            defaultDurationMs: 10000
        )
    }

    private static func nowMillis() -> Int64 {
        return Int64(CACurrentMediaTime() * 1000.0)
    }
}
