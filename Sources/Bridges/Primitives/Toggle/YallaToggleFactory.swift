import UIKit
import YallaComponents

public final class YallaToggleFactory: NSObject, ToggleFactory {
    public override init() { super.init() }

    public func create(
        initialChecked: Bool,
        initialEnabled: Bool,
        thumbArgb: Int64,
        trackArgb: Int64,
        onCheckedChange: @escaping (KotlinBoolean) -> Void
    ) -> ToggleHandle {
        let toggle = UISwitch()
        toggle.isOn = initialChecked
        toggle.isEnabled = initialEnabled
        if thumbArgb != 0 { toggle.thumbTintColor = UIColor(argb: thumbArgb) }
        if trackArgb != 0 { toggle.onTintColor = UIColor(argb: trackArgb) }
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
                toggle?.setOn(newChecked.boolValue, animated: true)
            },
            setEnabled: { [weak toggle] newEnabled in
                toggle?.isEnabled = newEnabled.boolValue
            },
            setColors: { [weak toggle] newThumbArgb, newTrackArgb in
                guard let toggle else { return }
                let thumb = newThumbArgb.int64Value
                let track = newTrackArgb.int64Value
                toggle.thumbTintColor = thumb == 0 ? nil : UIColor(argb: thumb)
                toggle.onTintColor = track == 0 ? nil : UIColor(argb: track)
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
