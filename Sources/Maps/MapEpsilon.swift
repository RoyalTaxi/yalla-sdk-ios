import Foundation

/// Single source of the approximate-equality thresholds used to dedup camera/center emissions on the
/// iOS renderers. Both `GoogleMapRenderer.cameraEpsilonEqual` and `LibreMapRenderer.centerEpsilonEqual`
/// read these, so the "what counts as the same camera" definition lives once instead of as bare
/// literals scattered per renderer. (The ideal home is a shared `CameraPosition.approximatelyEquals()`
/// in commonMain — see review #16 — which would also subsume the Kotlin wrapper + Android copies; that
/// crosses into the KMP framework and is out of this module's scope.)
enum MapEpsilon {
    /// Two latitudes/longitudes closer than this (degrees, ~0.1m) are treated as the same point.
    static let positionDegrees = 1e-6
    /// Two zoom levels closer than this are treated as equal.
    static let zoom: Float = 1e-3
    /// Two bearings/tilts closer than this (degrees) are treated as equal.
    static let angleDegrees = 0.1
}
