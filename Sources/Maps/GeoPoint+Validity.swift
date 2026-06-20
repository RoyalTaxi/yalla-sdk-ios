import YallaComponents

extension GeoPoint {
    /// Whether this point represents a real fix rather than the absent-sentinel `GeoPoint.Zero`
    /// (null island) that `DriverMotionModel.sample` returns before the first fix and that the rest
    /// of the stack filters as "no fix".
    ///
    /// Defined once and shared by both renderers' `fitBounds` so the absent-sentinel decision isn't
    /// hand-coded twice. Uses `!(lat == 0 && lng == 0)` so legitimate equator `(0, lng)` and
    /// prime-meridian `(lat, 0)` fixes are KEPT — only exact `(0, 0)` is treated as absent. (The
    /// residual conflation of a real `(0,0)` fix with "absent" is a contract decision that ideally
    /// lives in the common model, not here; this consolidates the renderer-local duplication.)
    var hasFix: Bool {
        !(lat == 0 && lng == 0)
    }
}
