import UIKit

/// Single source of truth for a sheet's measured height and its custom detent.
///
/// Before this extraction, three writers (`viewWillAppear`, `viewDidLayoutSubviews`,
/// `updateContentHeight`) mutated `measuredHeight` directly on the `Sheet` view controller, each
/// with its own epsilon guard, its own `hasReportedContentHeight` bookkeeping, and its own async
/// `invalidateDetents()` — the exact dual-path tangle that produced the prior height-loop bug.
///
/// This plain object owns that state so the height math is reasoned about (and unit-testable)
/// in one place. It preserves the committed height-loop fix verbatim:
///  - `detentEpsilon` coalescing on every write,
///  - the Auto-Layout path (`requestLayoutHeight`) only applies while content has not yet been
///    reported (`!hasReportedContentHeight`) and defers its `invalidateDetents()` to the next
///    main-loop turn,
///  - the Compose path (`requestContentHeight`) animates only after the first report.
///
/// Each sheet subtype drives exactly one input in practice: UIKit-measured sheets
/// (Action/Selection/Confirmation/DatePicker) use the layout path; Compose-measured sheets
/// (Content/Shell) use the content-callback path.
final class SheetDetentController {
    static let contentDetentID = UISheetPresentationController.Detent.Identifier("content")
    static let detentEpsilon: CGFloat = 1

    /// Latest applied height; the custom detent reads this. `nil` until the first measurement.
    private(set) var measuredHeight: CGFloat?
    /// Becomes true once the Compose callback has reported a height at least once. Gates the
    /// Auto-Layout path and selects animated-vs-immediate detent invalidation.
    private(set) var hasReportedContentHeight = false

    /// Whether this sheet sizes itself to content (custom detent) or fills (`.large`).
    private let sizesToContent: Bool
    /// Invoked when the detent must be recomputed; `animated` mirrors the previous inline
    /// `animateChanges { invalidateDetents() }` vs bare `invalidateDetents()` choice. The closure
    /// is responsible for any main-thread dispatch.
    private let invalidate: (_ animated: Bool) -> Void

    init(sizesToContent: Bool, invalidate: @escaping (_ animated: Bool) -> Void) {
        self.sizesToContent = sizesToContent
        self.invalidate = invalidate
    }

    /// Reset for a fresh presentation (mirrors `viewWillAppear`'s `hasReportedContentHeight = false`).
    func reset() {
        hasReportedContentHeight = false
    }

    /// Seed the initial height synchronously without invalidating (mirrors `viewWillAppear`'s
    /// `measuredHeight = preferredContentHeight()?.rounded()`).
    func seedInitialHeight(_ height: CGFloat?) {
        guard sizesToContent else { return }
        measuredHeight = height?.rounded()
    }

    /// Auto-Layout measurement from `viewDidLayoutSubviews`. No-op once content has been reported,
    /// or while the change is within epsilon. Defers invalidation to the next main-loop turn.
    func requestLayoutHeight(_ height: CGFloat?) {
        guard sizesToContent, !hasReportedContentHeight, let h = height?.rounded() else { return }
        if let current = measuredHeight, abs(h - current) < Self.detentEpsilon { return }
        measuredHeight = h
        DispatchQueue.main.async { [weak self] in
            self?.invalidate(true)
        }
    }

    /// Compose-reported measurement from `updateContentHeight`. Animates only after the first
    /// report; the first report invalidates without animation.
    func requestContentHeight(_ total: CGFloat) {
        if let current = measuredHeight, abs(total - current) < Self.detentEpsilon { return }
        measuredHeight = total
        let animate = hasReportedContentHeight
        hasReportedContentHeight = true
        DispatchQueue.main.async { [weak self] in
            self?.invalidate(animate)
        }
    }

    /// The detents for the presentation controller: a custom content-sized detent when sizing to
    /// content, otherwise `.large`.
    @available(iOS 16.0, *)
    func makeDetents() -> [UISheetPresentationController.Detent] {
        guard sizesToContent else { return [.large()] }
        let content = UISheetPresentationController.Detent.custom(identifier: Self.contentDetentID) { [weak self] context in
            guard let self, let h = self.measuredHeight else { return context.maximumDetentValue * 0.5 }
            return min(h, context.maximumDetentValue)
        }
        return [content]
    }
}
