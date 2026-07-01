import UIKit
import YallaComponents   // see SpikeMapSurface.swift import note + SPIKE_README BLOCKER

/// SPIKE ONLY. Owns the CADisplayLink and pumps the Kotlin `PoseDriver` once per frame, measuring
/// the frame budget the Kotlin->Swift pose pushes consume.
///
/// MEASUREMENT METHOD
/// ------------------
/// CADisplayLink fires on the main thread right before each screen refresh. We run the whole pose
/// push inside the callback and measure two things per frame:
///   1. `work`  = wall time spent inside our callback (the Kotlin tick + Swift mutations). This is
///      the direct cost of the boundary crossings.
///   2. `gap`   = link.targetTimestamp - link.timestamp, the time the system allotted for this
///      frame. On a 60 Hz display preferredFramesPerSecond=30 makes this ~0.0333s. A *dropped*
///      frame shows up as a gap of ~2x the nominal (the link skipped a vsync because the previous
///      callback overran). We count those.
///
/// A mode "holds frame rate" if `work` stays under the per-frame budget (here 1000/30 = 33.3 ms,
/// but really we care about staying under the *display* refresh, 16.6 ms on 60 Hz, because anything
/// over that on the main thread janks the whole UI even if the link is set to 30 Hz). We report
/// against BOTH so the decision is unambiguous.
public final class SpikeHarness: NSObject {

    public struct Result {
        public let mode: String
        public let markerCount: Int
        public let frames: Int
        public let avgWorkMs: Double
        public let p95WorkMs: Double
        public let maxWorkMs: Double
        public let droppedFrames: Int
        public let over16ms: Int   // frames whose work exceeded one 60Hz refresh
        public let over33ms: Int   // frames whose work exceeded the 30Hz budget
    }

    private let surface: SpikeMapSurface
    private var driver: PoseDriver!
    private var link: CADisplayLink?

    private var workSamplesMs: [Double] = []
    private var droppedFrames = 0
    private var framesTarget = 0
    private var modeLabel = ""
    private var markerCount = 0
    private var onDone: ((Result) -> Void)?

    public init(surface: SpikeMapSurface) {
        self.surface = surface
        super.init()
    }

    /// Runs ONE mode for `frames` frames, then calls `completion` with the result.
    /// Spawns the markers, builds the Kotlin driver for `mode`, and starts the link.
    public func run(mode: SpikeMode, markerCount: Int, frames: Int, completion: @escaping (Result) -> Void) {
        surface.reset()
        for i in 0..<markerCount {
            surface.addMarker(id: "spike-\(i)", lat: 41.3111 + Double(i) * 0.0002, lng: 69.2797 + Double(i) * 0.0002)
        }
        // Build the Kotlin driver. UNCERTAINTY #2: `SpikeMode` is a Kotlin enum; in Swift its cases
        // are `SpikeMode.perMarker` / `SpikeMode.batched` (Kotlin SCREAMING_SNAKE -> Swift camelCase,
        // accessed as `.shared`-less enum entries). Adjust if the projection differs.
        self.driver = PoseDriver(surface: surface, mode: mode, markerCount: Int32(markerCount))
        self.modeLabel = (mode == SpikeMode.perMarker) ? "PER_MARKER" : "BATCHED"
        self.markerCount = markerCount
        self.framesTarget = frames
        self.workSamplesMs.removeAll(keepingCapacity: true)
        self.droppedFrames = 0
        self.onDone = completion

        let l = CADisplayLink(target: self, selector: #selector(onFrame(_:)))
        l.preferredFramesPerSecond = 30   // same cadence as the production MarkerMotionDriver (link.preferredFramesPerSecond = 30)
        l.add(to: .main, forMode: .common)
        self.link = l
    }

    @objc private func onFrame(_ link: CADisplayLink) {
        // Detect a dropped frame: the system allotted ~2x (or more) the nominal interval, meaning a
        // vsync was skipped. duration is the nominal refresh; (target - timestamp) is what we got.
        let nominal = link.duration > 0 ? link.duration : (1.0 / 60.0)
        let allotted = link.targetTimestamp - link.timestamp
        if allotted > nominal * 1.5 {
            droppedFrames += Int((allotted / nominal).rounded()) - 1
        }

        let t0 = CACurrentMediaTime()
        // PUMP KOTLIN. frameMs is the host frame timestamp in ms — same shape as FrameClock's Flow<Long>.
        driver.tick(frameMs: Int64(link.timestamp * 1000.0))
        let workMs = (CACurrentMediaTime() - t0) * 1000.0
        workSamplesMs.append(workMs)

        if workSamplesMs.count >= framesTarget {
            finish()
        }
    }

    private func finish() {
        link?.invalidate()
        link = nil
        let sorted = workSamplesMs.sorted()
        let avg = workSamplesMs.reduce(0, +) / Double(max(1, workSamplesMs.count))
        let p95 = sorted.isEmpty ? 0 : sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.95))]
        let result = Result(
            mode: modeLabel,
            markerCount: markerCount,
            frames: workSamplesMs.count,
            avgWorkMs: avg,
            p95WorkMs: p95,
            maxWorkMs: sorted.last ?? 0,
            droppedFrames: droppedFrames,
            over16ms: workSamplesMs.filter { $0 > 16.6 }.count,
            over33ms: workSamplesMs.filter { $0 > 33.3 }.count
        )
        let done = onDone
        onDone = nil
        done?(result)
    }
}

public extension SpikeHarness.Result {
    var prettyLine: String {
        String(
            format: "%@ N=%-3d  avg %.2fms  p95 %.2fms  max %.2fms  >16.6ms:%d  >33.3ms:%d  dropped:%d  (frames %d)",
            mode, markerCount, avgWorkMs, p95WorkMs, maxWorkMs, over16ms, over33ms, droppedFrames, frames
        )
    }
}
