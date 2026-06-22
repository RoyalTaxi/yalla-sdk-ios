import UIKit

extension UIViewController {
    private static let maxPresentAttempts = 60

    func presentSerialized(_ vc: UIViewController, animated: Bool, attempt: Int = 0, onGiveUp: @escaping () -> Void = {}) {
        if vc.presentingViewController != nil { return }
        guard let presented = presentedViewController else {
            present(vc, animated: animated)
            return
        }
        guard attempt < Self.maxPresentAttempts else {
            onGiveUp()
            return
        }
        if let coordinator = presented.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1, onGiveUp: onGiveUp)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1, onGiveUp: onGiveUp)
            }
        }
    }
}
