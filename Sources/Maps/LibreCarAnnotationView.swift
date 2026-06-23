import UIKit
import MapLibre

/// A center-anchored, rotatable MapLibre annotation view for the driver ("car") marker.
///
/// `MLNPointAnnotation` rendered through `imageFor:` cannot rotate — MapLibre draws its image
/// upright regardless of any heading — which is why the car used to glide position-only and drop
/// `Pose.bearing`. This view hosts the car image in a centered `UIImageView` and rotates *that
/// subview* via `CGAffineTransform`, exactly like the proven `UniversalMarker` path in the
/// colleagues' MapPack. The displayed angle is `pose.bearing - mapCameraBearing`, re-applied
/// whenever the camera rotates (see `LibreMapRenderer.regionDidChange`), so the car keeps
/// pointing along its true world heading even when the map itself is rotated.
///
/// The view is center-anchored: `centerOffset` stays zero and the image is centered in the view's
/// bounds, so rotation pivots about the car's center rather than a corner.
final class LibreCarAnnotationView: MLNAnnotationView {

    private let imageView = UIImageView()

    /// Last display angle (radians) applied to the image, cached to skip redundant transforms.
    private var lastAppliedAngle: CGFloat?

    /// The marker's world heading in degrees (0..360), independent of the map camera.
    private(set) var worldHeadingDegrees: CLLocationDirection = 0

    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        // The view must not be scaled/flattened by MapLibre; we manage rotation ourselves.
        isUserInteractionEnabled = false
        scalesWithViewingDistance = false
        rotatesToMatchCamera = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets (or replaces) the car image and sizes the view to it, keeping the image centered so
    /// rotation pivots about the car's middle.
    func setImage(_ image: UIImage) {
        imageView.image = image
        let size = image.size
        bounds = CGRect(origin: .zero, size: size)
        // Reset rotation before laying out the frame, then restore it.
        imageView.transform = .identity
        imageView.frame = CGRect(origin: .zero, size: size)
        imageView.center = CGPoint(x: size.width / 2, y: size.height / 2)
        centerOffset = .zero
        if let angle = lastAppliedAngle {
            imageView.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    /// Stores the latest world heading; the displayed angle is recomputed against the camera by
    /// ``applyRotation(cameraBearing:)``.
    func setWorldHeading(_ degrees: CLLocationDirection) {
        worldHeadingDegrees = degrees
    }

    /// Rotates the image to `worldHeading - cameraBearing`. Idempotent within a small epsilon so
    /// camera-change spam does not thrash the transform.
    func applyRotation(cameraBearing: CLLocationDirection) {
        let display = LibreCarAnnotationView.normalize(worldHeadingDegrees - cameraBearing)
        let angle = CGFloat(display * .pi / 180.0)
        if let last = lastAppliedAngle, abs(angle - last) <= 0.0001 { return }
        lastAppliedAngle = angle
        imageView.transform = CGAffineTransform(rotationAngle: angle)
    }

    private static func normalize(_ value: CLLocationDirection) -> CLLocationDirection {
        var angle = value.truncatingRemainder(dividingBy: 360)
        if angle > 180 { angle -= 360 }
        if angle < -180 { angle += 360 }
        return angle
    }
}
