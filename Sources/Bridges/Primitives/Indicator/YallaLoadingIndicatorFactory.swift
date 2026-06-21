import UIKit
import YallaComponents

/// The iOS native implementation of the Kotlin `LoadingIndicatorFactory` Compose↔native bridge protocol.
public final class YallaLoadingIndicatorFactory: NSObject, LoadingIndicatorFactory {
    /// Creates the factory. Instantiated by the Kotlin bridge as the `LoadingIndicatorFactory` conformance.
    public override init() { super.init() }

    /// Builds a native, already-animating activity indicator.
    /// - Parameter color: packed-ARGB tint; `0` means the system default. The returned handle's
    ///   `setColor` closure updates the live indicator and is marshalled to the main thread.
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
