import UIKit
import MapLibre
// VERIFIED: carto has NO iOS framework (commonMain/commonTest only; not in the YallaComponents
// umbrella). For the spike, host PoseDriver.kt in `components` and import the umbrella iOS links:
import YallaComponents
// If carto later ships its own framework (baseName "Yalla"+"Carto"), switch to `import YallaCarto`.
// See SPIKE_README "VERIFIED BLOCKER" + RUN step 1.

/// SPIKE ONLY. Wraps a MapLibre MLNMapView and conforms to the Kotlin `SpikeSurface` protocol so the
/// commonMain `PoseDriver` (running in YallaCarto.framework) can call back into Swift per frame —
/// the exact Kotlin/Native -> Swift boundary the production carto motion loop will cross.
///
/// Mirrors the real surface's annotation handling:
///  - addMarker -> MLNPointAnnotation added to the map (LibreMapRenderer renderedAnnotations pattern,
///    yalla-sdk-ios/Sources/Maps/LibreMapRenderer.swift:23).
///  - setMarkerPose -> mutate annotation.coordinate + rotate the car view, exactly like
///    LibreMapRenderer.applyAnnotationPoses (LibreMapRenderer.swift:463-473).
///
/// CONFORMANCE: `NSObject, SpikeSurface` is the same shape as the production
/// `LibreMapRenderer: NSObject, IosMapRenderer, MLNMapViewDelegate` (LibreMapRenderer.swift:5) and
/// `YallaSnackbarFactory: NSObject, SnackbarFactory`. That is the proven interop pattern here:
/// a Kotlin interface surfaced as an ObjC protocol, implemented by a Swift NSObject subclass.
public final class SpikeMapSurface: NSObject, SpikeSurface, MLNMapViewDelegate {

    private(set) var mapView: MLNMapView!
    private var annotations: [String: MLNPointAnnotation] = [:]
    private var views: [String: SpikeCarView] = [:]

    // Counts how many Swift-side pose mutations actually happened, for sanity-checking the run.
    private(set) var appliedCount: Int = 0

    init(styleURL: String) {
        super.init()
        let mv = MLNMapView(frame: .zero, styleURL: URL(string: styleURL))
        mv.delegate = self
        mv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mv.isRotateEnabled = false
        mv.isPitchEnabled = false
        mv.showsAttributionButton = false
        mv.showsLogoView = false
        mv.compassView.isHidden = true
        mv.setCenter(CLLocationCoordinate2D(latitude: 41.3111, longitude: 69.2797), zoomLevel: 13, animated: false)
        self.mapView = mv
    }

    func addMarker(id: String, lat: Double, lng: Double) {
        let a = MLNPointAnnotation()
        a.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        a.title = id
        annotations[id] = a
        mapView.addAnnotation(a)
    }

    func reset() {
        if !annotations.isEmpty { mapView.removeAnnotations(Array(annotations.values)) }
        annotations.removeAll()
        views.removeAll()
        appliedCount = 0
    }

    // MARK: - SpikeSurface (called by Kotlin PoseDriver across the boundary)

    /// PER_MARKER mode: invoked once per marker per frame from Kotlin. THE crossing under test.
    /// Signature note: Kotlin `setMarkerPose(id: String, lat: Double, lng: Double, bearing: Float)`
    /// is projected to Swift as `setMarkerPoseId(_:lat:lng:bearing:)` and `bearing` becomes
    /// `Float` (KotlinFloat is NOT used for non-null primitive value params — see UNCERTAINTY #3).
    public func setMarkerPose(id: String, lat: Double, lng: Double, bearing: Float) {
        guard let a = annotations[id] else { return }
        a.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        views[id]?.setHeading(CGFloat(bearing))
        appliedCount += 1
    }

    /// BATCHED mode: invoked once per frame with all markers.
    /// Kotlin `applyPoses(ids: List<String>, lats: DoubleArray, lngs: DoubleArray, bearings: FloatArray)`
    /// projects to Swift roughly as `applyPosesIds(_:lats:lngs:bearings:)`, with `ids` as
    /// `[String]`(KotlinArray bridges as NSArray-backed), `lats/lngs` as `KotlinDoubleArray`,
    /// `bearings` as `KotlinFloatArray`. UNCERTAINTY #4: primitive arrays do NOT bridge to Swift
    /// `[Double]`/`[Float]` — they are `KotlinDoubleArray`/`KotlinFloatArray` and must be indexed via
    /// `.get(index:)`, not subscripting. The code below uses `.get(index:)` accordingly.
    public func applyPoses(ids: [String], lats: KotlinDoubleArray, lngs: KotlinDoubleArray, bearings: KotlinFloatArray) {
        let n = ids.count
        for i in 0..<n {
            guard let a = annotations[ids[i]] else { continue }
            a.coordinate = CLLocationCoordinate2D(
                latitude: lats.get(index: Int32(i)),
                longitude: lngs.get(index: Int32(i))
            )
            views[ids[i]]?.setHeading(CGFloat(bearings.get(index: Int32(i))))
            appliedCount += 1
        }
    }

    // MARK: - MLNMapViewDelegate

    public func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        guard let point = annotation as? MLNPointAnnotation, let id = point.title ?? nil else { return nil }
        let reuse = "spike-car"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuse) as? SpikeCarView)
            ?? SpikeCarView(annotation: annotation, reuseIdentifier: reuse)
        views[id] = view
        return view
    }
}

/// Minimal rotatable annotation view — stand-in for LibreCarAnnotationView so bearing application has
/// the same per-frame transform cost as production (LibreCarAnnotationView.applyRotation,
/// yalla-sdk-ios/Sources/Maps/LibreCarAnnotationView.swift:58-70).
final class SpikeCarView: MLNAnnotationView {
    private let dot = UIView()
    private var lastAngle: CGFloat = .greatestFiniteMagnitude

    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        dot.frame = bounds
        dot.backgroundColor = .systemBlue
        dot.layer.cornerRadius = 3
        addSubview(dot)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setHeading(_ degrees: CGFloat) {
        let angle = degrees * .pi / 180.0
        if abs(angle - lastAngle) <= 0.0001 { return }
        lastAngle = angle
        dot.transform = CGAffineTransform(rotationAngle: angle)
    }
}
