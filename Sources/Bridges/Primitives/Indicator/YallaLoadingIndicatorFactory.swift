import UIKit
import YallaComponents

public final class YallaLoadingIndicatorFactory: NSObject, LoadingIndicatorFactory {
    public override init() { super.init() }

    public func create(color: Int64) -> LoadingIndicatorHandle {
        let indicator = UIActivityIndicatorView(style: .medium)
        if color != 0 { indicator.color = UIColor(argb: color) }
        indicator.startAnimating()

        let viewController = UIViewController()
        viewController.view = indicator

        return LoadingIndicatorHandle(
            viewController: viewController,
            setColor: { [weak indicator] newColor in
                let value = newColor.int64Value
                indicator?.color = value == 0 ? nil : UIColor(argb: value)
            }
        )
    }
}

private extension UIColor {
    convenience init(argb: Int64) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
