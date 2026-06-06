import UIKit
import Resources
import YallaComponents

public final class YallaIconButtonFactory: NSObject, IconButtonFactory {
    public override init() { super.init() }

    public func create(
        icon: String,
        shape: IconButtonShape,
        iconArgb: Int64,
        containerArgb: Int64,
        onClick: @escaping () -> Void
    ) -> IconButtonHandle {
        var config: UIButton.Configuration = {
            if #available(iOS 26.0, *) {
                return .glass()
            } else {
                return .tinted()
            }
        }()
        config.cornerStyle = .capsule
        config.image = YallaResources.platformImage(icon)?.withRenderingMode(.alwaysTemplate)
        config.baseForegroundColor = iconArgb != 0 ? UIColor(argb: iconArgb) : UIColor.yalla("icon_base")
        if containerArgb != 0 {
            config.baseBackgroundColor = UIColor(argb: containerArgb)
        }

        let button = UIButton(
            configuration: config,
            primaryAction: UIAction { _ in onClick() }
        )

        let viewController = UIViewController()
        viewController.view = button

        return IconButtonHandle(
            viewController: viewController,
            setIcon: { [weak button] newIcon in
                guard let button else { return }
                var updated = button.configuration
                updated?.image = YallaResources.platformImage(newIcon)?.withRenderingMode(.alwaysTemplate)
                button.configuration = updated
            },
            setColors: { [weak button] iconArgb, containerArgb in
                guard let button else { return }
                var updated = button.configuration
                let iconValue = iconArgb.int64Value
                let containerValue = containerArgb.int64Value
                if iconValue != 0 { updated?.baseForegroundColor = UIColor(argb: iconValue) }
                if containerValue != 0 { updated?.baseBackgroundColor = UIColor(argb: containerValue) }
                button.configuration = updated
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
