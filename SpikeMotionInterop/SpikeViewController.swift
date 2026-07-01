import UIKit
import YallaComponents   // for SpikeMode (.perMarker / .batched); see SPIKE_README BLOCKER

/// SPIKE ONLY. Drop-in UIViewController: shows the MapLibre map, a marker-count picker, and a Run
/// button. Run drives BOTH modes (PER_MARKER then BATCHED) for the selected N over a fixed number of
/// frames and prints a result line per mode to the on-screen log and to the console.
///
/// To launch: set this as the root VC (see SPIKE_README "RUN"). No storyboard needed.
public final class SpikeViewController: UIViewController {

    // A demo style works without a token; swap for your real MapLibre style URL if you have one.
    // UNCERTAINTY #6: the style URL must be reachable on-device; an unreachable style leaves the map
    // blank but the boundary measurement still runs (annotations mutate regardless of tiles).
    private let styleURL = "https://demotiles.maplibre.org/style.json"

    private lazy var surface = SpikeMapSurface(styleURL: styleURL)
    private lazy var harness = SpikeHarness(surface: surface)

    private let counts = [10, 50, 100, 200]
    private var selectedCount = 50
    private let framesPerRun = 300   // 300 frames at 30 Hz = ~10 s per mode. Long enough to surface jank.

    private let segmented = UISegmentedControl(items: ["10", "50", "100", "200"])
    private let runButton = UIButton(type: .system)
    private let logView = UITextView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let map = surface.mapView!
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)

        segmented.selectedSegmentIndex = 1
        segmented.addTarget(self, action: #selector(countChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false

        runButton.setTitle("Run both modes", for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        runButton.translatesAutoresizingMaskIntoConstraints = false

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.backgroundColor = .secondarySystemBackground
        logView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmented)
        view.addSubview(runButton)
        view.addSubview(logView)

        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            map.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),

            segmented.topAnchor.constraint(equalTo: map.bottomAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            runButton.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            runButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            logView.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 12),
            logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        log("Spike ready. Pick N, tap Run. Each run = PER_MARKER then BATCHED, \(framesPerRun) frames each.")
        log("DECISION: if PER_MARKER drops frames / blows the 16.6ms budget where BATCHED holds, add applyPoses to MapSurface.")
    }

    @objc private func countChanged() {
        selectedCount = counts[segmented.selectedSegmentIndex]
    }

    @objc private func runTapped() {
        runButton.isEnabled = false
        segmented.isEnabled = false
        log("\n=== Run N=\(selectedCount) ===")
        // Run PER_MARKER, then on completion run BATCHED, then re-enable.
        harness.run(mode: .perMarker, markerCount: selectedCount, frames: framesPerRun) { [weak self] r1 in
            guard let self else { return }
            self.log(r1.prettyLine)
            print("[SPIKE] " + r1.prettyLine)
            self.harness.run(mode: .batched, markerCount: self.selectedCount, frames: self.framesPerRun) { [weak self] r2 in
                guard let self else { return }
                self.log(r2.prettyLine)
                print("[SPIKE] " + r2.prettyLine)
                self.log(self.verdict(perMarker: r1, batched: r2))
                self.runButton.isEnabled = true
                self.segmented.isEnabled = true
            }
        }
    }

    private func verdict(perMarker: SpikeHarness.Result, batched: SpikeHarness.Result) -> String {
        let pmJanks = perMarker.over16ms > perMarker.frames / 20 || perMarker.droppedFrames > 0
        let batchHolds = batched.over16ms <= batched.frames / 20 && batched.droppedFrames == 0
        if pmJanks && batchHolds {
            return ">>> VERDICT N=\(selectedCount): PER_MARKER janks, BATCHED holds -> ADD applyPoses to MapSurface."
        } else if !pmJanks {
            return ">>> VERDICT N=\(selectedCount): PER_MARKER holds -> keep simple per-marker path."
        } else {
            return ">>> VERDICT N=\(selectedCount): both struggle -> the loop itself (not just the crossing) is the problem; investigate."
        }
    }

    private func log(_ s: String) {
        logView.text = (logView.text ?? "") + "\n" + s
        let end = NSRange(location: (logView.text as NSString).length, length: 0)
        logView.scrollRangeToVisible(end)
    }
}
