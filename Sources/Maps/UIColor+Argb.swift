import UIKit

extension UIColor {
    /// Builds a color from a packed 0xAARRGGBB integer, the shared marker/route/circle color
    /// representation produced by the common `uz.yalla.maps` model (`colorArgb: Int`).
    convenience init(argb: Int32) {
        let value = UInt32(bitPattern: argb)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: CGFloat((value >> 24) & 0xFF) / 255.0
        )
    }
}
