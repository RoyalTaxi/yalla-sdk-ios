import UIKit
import Resources
import YallaComponents

private let iconButtonColorUnset = Int64.min

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
        let tint = iconTint(iconArgb)

        if #available(iOS 26.0, *), shape == .circle, containerArgb == iconButtonColorUnset {
            let glassButton = GlassIconButton(image: image, tint: tint, onClick: onClick)
            let viewController = UIViewController()
            viewController.view = glassButton
            return IconButtonHandle(
                viewController: viewController,
                setIcon: { [weak glassButton] newIcon in
                    onMain {
                        glassButton?.setImage(YallaResources.platformImage(newIcon)?.withRenderingMode(.alwaysTemplate))
                    }
                },
                setColors: { [weak glassButton] iconArgb, _, _ in
                    onMain {
                        let value = iconArgb.int64Value
                        glassButton?.setTint(iconTint(value))
                    }
                }
            )
        }

        var config = UIButton.Configuration.plain()
        config.image = image
        config.baseForegroundColor = tint
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = argbColor(containerArgb) ?? .clear
        background.cornerRadius = (shape == .circle) ? 999 : 12
        if borderArgb != iconButtonColorUnset {
            background.strokeColor = UIColor(argb: borderArgb)
            background.strokeWidth = 1
        }
        config.background = background

        let button = UIButton(
            configuration: config,
            primaryAction: UIAction { _ in
                Haptics.impact(.light)
                onClick()
            }
        )

        let viewController = UIViewController()
        viewController.view = button

        return IconButtonHandle(
            viewController: viewController,
            setIcon: { [weak button] newIcon in
                onMain {
                    guard let button else { return }
                    var updated = button.configuration
                    updated?.image = YallaResources.platformImage(newIcon)?.withRenderingMode(.alwaysTemplate)
                    button.configuration = updated
                }
            },
            setColors: { [weak button] iconArgb, containerArgb, borderArgb in
                onMain {
                    guard let button else { return }
                    var updated = button.configuration
                    let iconValue = iconArgb.int64Value
                    let containerValue = containerArgb.int64Value
                    let borderValue = borderArgb.int64Value
                    updated?.baseForegroundColor = iconTint(iconValue)
                    updated?.background.backgroundColor = argbColor(containerValue) ?? .clear
                    if borderValue != iconButtonColorUnset {
                        updated?.background.strokeColor = UIColor(argb: borderValue)
                        updated?.background.strokeWidth = 1
                    } else {
                        updated?.background.strokeColor = nil
                        updated?.background.strokeWidth = 0
                    }
                    button.configuration = updated
                }
            }
        )
    }
}

private func argbColor(_ argb: Int64) -> UIColor? {
    argb == iconButtonColorUnset ? nil : UIColor(argb: argb)
}

private func iconTint(_ argb: Int64) -> UIColor {
    argbColor(argb) ?? (UIColor.yalla("icon_base") ?? .label)
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

    @objc private func handleTap() {
        Haptics.impact(.rigid)
        onClick()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
        imageView.frame = effectView.contentView.bounds
    }

    func setImage(_ image: UIImage?) { imageView.image = image }
    func setTint(_ color: UIColor) { imageView.tintColor = color }
}
