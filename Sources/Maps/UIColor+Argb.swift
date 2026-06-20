import UIKit

extension UIColor {
    /// Builds a color from a packed 0xAARRGGBB integer, the shared marker/route/circle color
    /// representation produced by the common `uz.yalla.maps` model (`colorArgb: Int`).
    ///
    /// The single source of truth for ARGB→`UIColor` on iOS. The `Int64` overload below routes here so
    /// the byte-unpacking exists once. (The three byte-identical private copies in `Sources/Bridges`
    /// — `YallaLoadingIndicatorFactory`/`YallaToggleFactory`/`YallaIconButtonFactory` — should be
    /// deleted in favor of this; they live in a different SPM target and are out of this module's scope.)
    convenience init(argb: Int32) {
        let value = UInt32(bitPattern: argb)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: CGFloat((value >> 24) & 0xFF) / 255.0
        )
    }

    /// `Int64` overload for callers holding the Kotlin `Int` widened to `Int64` across interop. Only the
    /// low 32 bits carry the packed 0xAARRGGBB value, so we truncate and reuse the `Int32` initializer.
    convenience init(argb: Int64) {
        self.init(argb: Int32(truncatingIfNeeded: argb))
    }
}
