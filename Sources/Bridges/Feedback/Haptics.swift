import UIKit

/// Centralized haptic feedback for the native component layer.
///
/// iOS users expect a tactile confirmation on meaningful actions — a success/error toast, a
/// confirmation tap, a selection, a destructive choice. The native layer previously emitted none,
/// which is one of the clearest "this isn't a real iOS app" signals. Each call creates a generator
/// and triggers it synchronously, so the generator stays alive through the feedback; the system
/// silently no-ops when the user has disabled haptics, so no extra guard is needed.
///
/// `UIFeedbackGenerator` is UIKit and must be constructed and triggered on the main thread. Every
/// method routes through `onMain`, so haptics are safe to call regardless of the caller's thread.
enum Haptics {
    /// A completed, positive action (e.g. a code accepted, a toast confirming success).
    static func success() { notify(.success) }

    /// A cautionary or destructive action (e.g. tapping a delete row).
    static func warning() { notify(.warning) }

    /// A failed action (e.g. a rejected code, an error toast).
    static func error() { notify(.error) }

    /// Moving between discrete options (e.g. picking a row in a selection sheet).
    static func selection() {
        onMain { UISelectionFeedbackGenerator().selectionChanged() }
    }

    /// A physical "tap" for button presses and commits. Use `.light`/`.rigid` for chrome buttons,
    /// `.medium` for primary confirmations.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        onMain { UIImpactFeedbackGenerator(style: style).impactOccurred() }
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        onMain { UINotificationFeedbackGenerator().notificationOccurred(type) }
    }
}
