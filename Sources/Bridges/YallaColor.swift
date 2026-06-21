import UIKit
import Resources

extension UIColor {
    static func yalla(_ name: String) -> UIColor? {
        UIColor(named: name, in: YallaResources.bundle, compatibleWith: nil)
    }

    /// Decodes the SDK's packed-ARGB color wire-format (a Kotlin `Int64`, channels `0xAARRGGBB`)
    /// into a `UIColor`. This is the single decode for the whole bridge surface — the factories
    /// receive colors as packed ints across the Compose↔native boundary. A value of `0` is the
    /// "use the token default" sentinel at the call sites and is never passed here.
    convenience init(argb: Int64) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
