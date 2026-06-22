import UIKit
import YallaComponents

public final class YallaToggleFactory: NSObject, ToggleFactory {
    public override init() { super.init() }

    public func create(
        initialChecked: Bool,
        initialEnabled: Bool,
        colors: ToggleColors,
        onCheckedChange: @escaping (KotlinBoolean) -> Void
    ) -> ToggleHandle {
        let toggle = UISwitch()
        toggle.isOn = initialChecked
        toggle.isEnabled = initialEnabled
        let colorBox = ColorBox(colors)
        Self.applyColors(colorBox.colors, to: toggle)
        toggle.addAction(
            UIAction { [weak toggle] _ in
                guard let toggle else { return }
                onCheckedChange(KotlinBoolean(value: toggle.isOn))
            },
            for: .valueChanged
        )

        let viewController = UIViewController()
        viewController.view = toggle

        return ToggleHandle(
            viewController: viewController,
            setChecked: { [weak toggle] newChecked in
                onMain {
                    guard let toggle else { return }
                    toggle.setOn(newChecked.boolValue, animated: true)
                    Self.applyColors(colorBox.colors, to: toggle)
                }
            },
            setEnabled: { [weak toggle] newEnabled in
                onMain {
                    guard let toggle else { return }
                    toggle.isEnabled = newEnabled.boolValue
                    Self.applyColors(colorBox.colors, to: toggle)
                }
            },
            setColors: { [weak toggle] newColors in
                onMain {
                    guard let toggle else { return }
                    colorBox.colors = newColors
                    Self.applyColors(newColors, to: toggle)
                }
            }
        )
    }

    private final class ColorBox {
        var colors: ToggleColors
        init(_ colors: ToggleColors) { self.colors = colors }
    }

    private static func applyColors(_ colors: ToggleColors, to toggle: UISwitch) {
        let enabled = toggle.isEnabled
        let checked = toggle.isOn
        let thumbArgb: Int64
        switch (checked, enabled) {
        case (true, true): thumbArgb = colors.checkedThumbArgb
        case (false, true): thumbArgb = colors.uncheckedThumbArgb
        case (true, false): thumbArgb = colors.disabledCheckedThumbArgb
        case (false, false): thumbArgb = colors.disabledUncheckedThumbArgb
        }
        let onTrackArgb = enabled ? colors.checkedTrackArgb : colors.disabledCheckedTrackArgb
        let offTrackArgb = enabled ? colors.uncheckedTrackArgb : colors.disabledUncheckedTrackArgb

        toggle.thumbTintColor = thumbArgb == 0 ? nil : UIColor(argb: thumbArgb)
        toggle.onTintColor = onTrackArgb == 0 ? nil : UIColor(argb: onTrackArgb)
        toggle.tintColor = offTrackArgb == 0 ? nil : UIColor(argb: offTrackArgb)
    }
}
