import UIKit
import YallaComponents

/// The iOS native implementation of the Kotlin `ToggleFactory` Compose↔native bridge protocol.
public final class YallaToggleFactory: NSObject, ToggleFactory {
    /// Creates the factory. Instantiated by the Kotlin bridge as the `ToggleFactory` conformance.
    public override init() { super.init() }

    /// Builds a native `UISwitch`-backed toggle.
    /// - Parameters:
    ///   - initialChecked: the initial on/off state.
    ///   - initialEnabled: whether the toggle starts interactive.
    ///   - colors: the full restyleable color set (each channel packed-ARGB; `0` means the system
    ///     default). A `UISwitch` renders thumb, on-track, and off-track tints, so the checked vs.
    ///     unchecked thumb/track and their disabled variants are selected for the current
    ///     checked/enabled state; the border channels have no native `UISwitch` analog.
    ///   - onCheckedChange: fired with the new value when the user toggles. The returned handle's
    ///     setters update the live toggle and are marshalled to the main thread.
    public func create(
        initialChecked: Bool,
        initialEnabled: Bool,
        colors: ToggleColors,
        onCheckedChange: @escaping (KotlinBoolean) -> Void
    ) -> ToggleHandle {
        let toggle = UISwitch()
        toggle.isOn = initialChecked
        toggle.isEnabled = initialEnabled
        // Hold the latest colors so the state setters can re-resolve tints (which color applies
        // depends on the live checked/enabled state) against the current restyle, not a stale one.
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

    /// Mutable holder for the latest pushed colors, shared by the handle's state setters so they
    /// re-resolve against the current restyle rather than a value captured at create time.
    private final class ColorBox {
        var colors: ToggleColors
        init(_ colors: ToggleColors) { self.colors = colors }
    }

    /// Resolves the thumb / on-track / off-track tints for the toggle's current checked + enabled
    /// state from the full color set. `0` for a channel leaves that tint at the system default.
    ///
    /// `UISwitch` exposes three tints: `thumbTintColor` (the knob), `onTintColor` (the on-track),
    /// and `tintColor` (the off-track outline). The thumb is the only one that varies with the
    /// current checked state here; the two track tints map to the checked/unchecked track colors,
    /// each chosen by the enabled state (UIKit shows whichever track matches the live on/off value).
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
