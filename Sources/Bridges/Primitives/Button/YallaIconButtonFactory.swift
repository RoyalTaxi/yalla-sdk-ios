import UIKit
import Resources
import YallaComponents

/// The iOS native implementation of the Kotlin `IconButtonFactory` Compose↔native bridge protocol.
public final class YallaIconButtonFactory: NSObject, IconButtonFactory {
    /// Creates the factory. Instantiated by the Kotlin bridge as the `IconButtonFactory` conformance.
    public override init() { super.init() }

    /// Builds a native icon button.
    /// - Parameters:
    ///   - icon: an asset-catalog image name in the SDK resource bundle (not a URL).
    ///   - shape: circle or rounded-rectangle container.
    ///   - iconArgb: packed-ARGB tint for the icon; `0` means use the `icon_base` token default.
    ///   - containerArgb: packed-ARGB container fill; `0` means transparent (and, on iOS 26 circles,
    ///     selects the glass-effect button).
    ///   - borderArgb: packed-ARGB border color; `0` means no border.
    ///   - onClick: fired when the button is tapped. The returned handle's `setIcon`/`setColors`
    ///     closures update the live button and are marshalled to the main thread.
    public func create(
        icon: String,
        shape: IconButtonShape,
        iconArgb: Int64,
        containerArgb: Int64,
        borderArgb: Int64,
        onClick: @escaping () -> Void
    ) -> IconButtonHandle {
        // TODO(quality, needs-decision): L2 — `argb == 0` is overloaded as "no color supplied", so a
        //  legitimately-computed fully-transparent color (0x00000000) collapses to the token/default
        //  branch. The fix (a `KotlinInt?`/isSet flag, or a reserved ARGB_UNSET sentinel) changes the
        //  Compose↔native protocol signatures (`IconButtonFactory.create(iconArgb:…)` etc.), a
        //  BREAKING change to the committed components.klib.api. Blocked on owner sign-off.
        let image = YallaResources.platformImage(icon)?.withRenderingMode(.alwaysTemplate)
        let tint: UIColor = iconArgb != 0 ? UIColor(argb: iconArgb) : (UIColor.yalla("icon_base") ?? .label)

        if #available(iOS 26.0, *), shape == .circle, containerArgb == 0 {
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
                        // The glass button renders neither a container fill nor a border, so only
                        // the icon tint is honored here.
                        let value = iconArgb.int64Value
                        if value != 0 { glassButton?.setTint(UIColor(argb: value)) }
                    }
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
                    if iconValue != 0 { updated?.baseForegroundColor = UIColor(argb: iconValue) }
                    updated?.background.backgroundColor = containerValue != 0 ? UIColor(argb: containerValue) : .clear
                    if borderValue != 0 {
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
