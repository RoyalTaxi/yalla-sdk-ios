import Foundation
import YallaComponents

/// Small rendering helpers shared verbatim by the Google and Libre iOS renderers.
///
/// These were duplicated identically in both `*MapRenderer`: a main-thread hop and a point-list
/// equality check. Hoisting them keeps the two backends in lockstep and is the iOS counterpart to
/// the Android `common/` extractions.
enum MapUtil {

    /// Runs `block` on the main thread, synchronously if already on it, else async-dispatched.
    static func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    /// Compares two geo-point lists for equality within ``MapEpsilon/routePointDegrees``. A `nil`
    /// left-hand list (no previously-seeded geometry) is never equal. Used to skip re-seeding a
    /// motion model / re-uploading a route source when the geometry has not meaningfully changed.
    static func pointsEqual(_ a: [GeoPoint]?, _ b: [GeoPoint]) -> Bool {
        guard let a = a, a.count == b.count else { return false }
        for i in 0..<a.count {
            if abs(a[i].lat - b[i].lat) > MapEpsilon.routePointDegrees ||
                abs(a[i].lng - b[i].lng) > MapEpsilon.routePointDegrees {
                return false
            }
        }
        return true
    }

    // Web-Mercator metres-per-pixel at zoom 0 / the equator. Mirrors the Android
    // `MapMath.BASE_METERS_PER_PIXEL` so the two platforms size geographic circles identically.
    private static let baseMetersPerPixel = 156_543.033_92

    /// On-screen radius doubling per zoom level, evaluated at the max MapLibre zoom (2^22). The
    /// circle-radius interpolation runs from the zoom-0 pixel radius up to this multiple at zoom 22.
    static let circleRadiusMaxZoomScale = 4_194_304.0

    /// Pixel radius at zoom 0 for a geographic circle of `radiusMeters` at the given latitude.
    /// MapLibre's `circleRadius` is in screen points, so a metres radius must be projected at the
    /// current zoom; this is the zoom-0 anchor the renderer's radius expression interpolates from.
    /// Mirrors the Android `MapMath.circleRadiusPixelsAtZoomZero`.
    static func circleRadiusPixelsAtZoomZero(radiusMeters: Double, lat: Double) -> Double {
        return radiusMeters / (baseMetersPerPixel * cos(lat * .pi / 180.0))
    }
}
