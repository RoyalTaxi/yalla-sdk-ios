import UIKit
import Resources

extension UIColor {
    static func yalla(_ name: String) -> UIColor? {
        UIColor(named: name, in: YallaResources.bundle, compatibleWith: nil)
    }
}
