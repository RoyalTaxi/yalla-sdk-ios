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
        borderArgb: Int64,
        onClick: @escaping () -> Void
    ) -> IconButtonHandle {
        let image = YallaResources.platformImage(icon)?.withRenderingMode(.alwaysTemplate)
        let tint: UIColor = iconArgb != 0 ? UIColor(argb: iconArgb) : (UIColor.yalla("icon_base") ?? .label)

        if #available(iOS 26.0, *), shape == .circle, containerArgb == 0 {
            let glassButton = GlassIconButton(image: image, tint: tint, onClick: onClick)
            let viewController = UIViewController()
            viewController.view = glassButton
            return IconButtonHandle(
                viewController: viewController,
                setIcon: { [weak glassButton] newIcon in
                    glassButton?.setImage(YallaResources.platformImage(newIcon)?.withRenderingMode(.alwaysTemplate))
                },
                setColors: { [weak glassButton] iconArgb, _ in
                    let value = iconArgb.int64Value
                    if value != 0 { glassButton?.setTint(UIColor(argb: value)) }
                }
            )
        }

        var config = UIButton.Configuration.plain()
        config.image = image
        config.baseForegroundColor = tint
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = containerArgb != 0 ? UIColor(argb: containerArgb) : .clear
        background.cornerRadius = (shape == .circle) ? 999 : 12
        if borderArgb != 0 {
            background.strokeColor = UIColor(argb: borderArgb)
            background.strokeWidth = 1
        }
        config.background = background

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
                updated?.background.backgroundColor = containerValue != 0 ? UIColor(argb: containerValue) : .clear
                button.configuration = updated
            }
        )
    }
}

@available(iOS 26.0, *)
private final class GlassIconButton: UIControl {
    private let effectView: UIVisualEffectView
    private let imageView = UIImageView()
    private let onClick: () -> Void

    init(image: UIImage?, tint: UIColor, onClick: @escaping () -> Void) {
        let glass = UIGlassEffect(style: .regular)
        glass.isInteractive = true
        effectView = UIVisualEffectView(effect: glass)
        self.onClick = onClick
        super.init(frame: .zero)
        effectView.cornerConfiguration = .capsule()
        effectView.isUserInteractionEnabled = false
        addSubview(effectView)
        imageView.image = image
        imageView.tintColor = tint
        imageView.contentMode = .center
        effectView.contentView.addSubview(imageView)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    @objc private func handleTap() { onClick() }

    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
        imageView.frame = effectView.contentView.bounds
    }

    func setImage(_ image: UIImage?) { imageView.image = image }
    func setTint(_ color: UIColor) { imageView.tintColor = color }
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
