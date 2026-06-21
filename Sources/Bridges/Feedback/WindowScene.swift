import UIKit

extension UIApplication {
    /// The window scene to render bridge UI into, preferring the most-foregrounded one but falling
    /// back across activation states. The stricter `foregroundActive + isKeyWindow` filter legitimately
    /// returns nil during scene transitions / multi-window / just after backgrounding, which would
    /// strand a snackbar or picker; this fallback keeps them presentable.
    static func activeBridgeWindowScene() -> UIWindowScene? {
        let priorityFor: (UIScene.ActivationState) -> Int = { state in
            switch state {
            case .foregroundActive: return 0
            case .foregroundInactive: return 1
            case .background: return 2
            case .unattached: return 3
            @unknown default: return 4
            }
        }
        return shared.connectedScenes
            .sorted { priorityFor($0.activationState) < priorityFor($1.activationState) }
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
