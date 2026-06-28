import UIKit

/// The sheet's 3-band layout shell as a dedicated `UIView`, extracted from the `Sheet` VC.
///
/// Owns the header / content / footer containers, their constraints (including the
/// `headerHeightConstraint` and `footerZeroHeightConstraint` the VC toggles), the rounded footer
/// corners, the two drop shadows, and the scroll-driven elevation logic. The `Sheet` VC sets
/// `view = SheetScaffoldView()` and coordinates; the builders (`setHeader`/`setFooter`/`setContent*`)
/// add their subviews into these containers.
///
/// Layout/behavior mirror the previous inline `buildScaffold()`/`configureShadow`/`updateElevation`
/// exactly — only the ownership moved out of the controller.
final class SheetScaffoldView: UIView {
    // Chrome constants — header/footer layout policy lives with the scaffold.
    static let headerHeight: CGFloat = 72
    static let footerHeight: CGFloat = 80
    static let footerButtonHeight: CGFloat = 64
    static let footerInset: CGFloat = 8
    static let footerHorizontalInset: CGFloat = 20

    let headerContainer = UIView()
    let contentContainer = UIView()
    let footerContainer = UIView()

    private(set) var headerHeightConstraint: NSLayoutConstraint!
    private(set) var footerZeroHeightConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        buildScaffold()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    private func buildScaffold() {
        headerContainer.backgroundColor = UIColor.yalla("background_base")
        footerContainer.backgroundColor = UIColor.yalla("background_base")
        footerContainer.layer.cornerRadius = 38
        footerContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        footerContainer.layer.masksToBounds = true
        contentContainer.clipsToBounds = true

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)
        [headerContainer, footerContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        configureShadow(headerContainer, yOffset: 3)
        configureShadow(footerContainer, yOffset: -3)

        headerHeightConstraint = headerContainer.heightAnchor.constraint(equalToConstant: 0)
        footerZeroHeightConstraint = footerContainer.heightAnchor.constraint(equalToConstant: 0)

        let footerSafeArea = footerContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        footerSafeArea.priority = .defaultHigh

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerContainer.topAnchor.constraint(equalTo: topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerHeightConstraint,

            footerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerContainer.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor),
            footerSafeArea,
            footerZeroHeightConstraint
        ])
        bringSubviewToFront(headerContainer)
        bringSubviewToFront(footerContainer)
    }

    private func configureShadow(_ container: UIView, yOffset: CGFloat) {
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: yOffset)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0
    }

    /// Toggle the header/footer drop shadows based on a scroll view's offset. Mirrors the previous
    /// `updateElevation()` — header shadows once scrolled off the top, footer shadows until the
    /// bottom is reached (and never while the footer is collapsed).
    func updateElevation(for scrollView: UIScrollView) {
        let atTop = scrollView.contentOffset.y <= 0.5
        let atBottom = scrollView.contentOffset.y + scrollView.bounds.height >= scrollView.contentSize.height - 0.5
        setShadow(headerContainer, visible: !atTop)
        setShadow(footerContainer, visible: !atBottom && !footerZeroHeightConstraint.isActive)
    }

    private func setShadow(_ container: UIView, visible: Bool) {
        let target: Float = visible ? 0.08 : 0
        guard container.layer.shadowOpacity != target else { return }
        container.layer.shadowOpacity = target
    }
}
