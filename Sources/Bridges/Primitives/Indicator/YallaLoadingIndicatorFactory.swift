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
                onMain {
                    let value = newColor.int64Value
                    indicator?.color = value == 0 ? nil : UIColor(argb: value)
                }
            }
        )
    }
}
