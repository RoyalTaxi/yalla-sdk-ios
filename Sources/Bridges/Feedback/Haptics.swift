import UIKit

enum Haptics {
    static func success() { notify(.success) }

    static func warning() { notify(.warning) }

    static func error() { notify(.error) }

    static func selection() {
        onMain { UISelectionFeedbackGenerator().selectionChanged() }
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        onMain { UIImpactFeedbackGenerator(style: style).impactOccurred() }
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        onMain { UINotificationFeedbackGenerator().notificationOccurred(type) }
    }
}
