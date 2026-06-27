import Foundation

enum MapEpsilon {
    static let positionDegrees = 1e-6
    static let zoom: Float = 1e-3
    static let angleDegrees = 0.1
    /// Tighter tolerance for comparing route-vertex coordinates (route geometry is exact, so this
    /// only absorbs floating-point noise from round-tripping through the SDK).
    static let routePointDegrees = 1e-7
}
