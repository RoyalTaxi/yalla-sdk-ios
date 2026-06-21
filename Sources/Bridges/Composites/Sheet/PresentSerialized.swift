import UIKit

extension UIViewController {
    /// The retry cap for waiting out an occupied presenter (~`maxPresentAttempts * one main-loop hop`).
    private static let maxPresentAttempts = 60

    /// Presents `vc`, first waiting out any in-flight transition of whatever this controller is
    /// already presenting. iOS refuses to present while the presenter is mid-transition — exactly
    /// what breaks sheet-to-sheet swaps: the coordinator dismisses the outgoing sheet and presents
    /// the incoming one in the same frame, so the new present lands while the old sheet is still
    /// animating out and is silently dropped (and on iOS 26 can throw).
    ///
    /// It never force-dismisses the current occupant: the outgoing sheet's own lifecycle dismisses
    /// it, so we only WAIT for the presenter to free up — chaining off the in-flight transition's
    /// coordinator, or polling a frame when something settled still occupies it. That avoids tearing
    /// down an unrelated modal (alert / share / Safari) that happens to be up. The attempt cap stops
    /// it spinning if the presenter never frees (e.g. a modal that's staying put).
    ///
    /// - Parameter onGiveUp: invoked if the presenter never frees within the cap so a caller with a
    ///   terminal-result contract (the media pickers) can complete instead of stranding the caller.
    ///   Defaults to a no-op for the sheet paths, which retry through their own lifecycle.
    func presentSerialized(_ vc: UIViewController, animated: Bool, attempt: Int = 0, onGiveUp: @escaping () -> Void = {}) {
        if vc.presentingViewController != nil { return } // already presented — don't double-present
        guard let presented = presentedViewController else {
            present(vc, animated: animated)
            return
        }
        guard attempt < Self.maxPresentAttempts else {
            onGiveUp() // give up rather than fight an unexpected modal
            return
        }
        if let coordinator = presented.transitionCoordinator {
            // A transition (the outgoing sheet's dismiss) is in flight — present once it completes.
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1, onGiveUp: onGiveUp)
            }
        } else {
            // Something settled still occupies the presenter — in a swap this is the outgoing sheet
            // a frame before its own dismiss runs. Wait a hop and retry; never dismiss it ourselves.
            DispatchQueue.main.async { [weak self] in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1, onGiveUp: onGiveUp)
            }
        }
    }
}
