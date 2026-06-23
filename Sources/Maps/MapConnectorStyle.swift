import Foundation

/// Shared style for the off-route honesty connector — the short line drawn from a driver's raw GPS
/// fix to the snapped point the car is rendered at while route-following.
///
/// Kept deliberately understated (thin, semi-transparent grey, dashed where the platform supports
/// it) so it reads as a hint, not a route. Both the Google and MapLibre renderers draw it from the
/// `RouteConnector` the motion model emits; neither computes its geometry.
enum MapConnectorStyle {
    /// 0x99 alpha grey (#8A8A8E), matching the muted system separator tone.
    static let colorArgb: Int32 = Int32(bitPattern: 0x998A8A8E)
    static let widthDp: Float = 2.0
    /// Above routes but below the car marker, so it visibly bridges GPS → car without occluding it.
    static let zIndex: Int32 = 50
    /// Dash pattern (on, off) in points, for renderers that support dashed strokes.
    static let dashLengthsPt: [NSNumber] = [4, 4]
}
