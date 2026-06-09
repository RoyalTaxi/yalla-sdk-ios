import UIKit
import Design
import YallaComponents

class Sheet: UIViewController {
    private let dismissEnabled: Bool
    private let sheetSwipeEnabled: Bool
    private let sizesToContent: Bool
    private let onDismissRequest: () -> Void

    private let headerContainer = UIView()
    private let contentContainer = UIView()
    private let footerContainer = UIView()
    private let titleLabel = UILabel()
    private var closeHandle: IconButtonHandle?
    private weak var elevationScrollView: UIScrollView?

    private var headerHeightConstraint: NSLayoutConstraint!
    private var footerZeroHeightConstraint: NSLayoutConstraint!

    private var measuredHeight: CGFloat?
    private var hasReportedContentHeight = false

    static let headerHeight: CGFloat = 72
    static let footerHeight: CGFloat = 80
    private static let footerButtonHeight: CGFloat = 64
    private static let footerInset: CGFloat = 8
    private static let footerHorizontalInset: CGFloat = 20

    private static let contentDetentID = UISheetPresentationController.Detent.Identifier("content")

    init(dismissEnabled: Bool, sheetSwipeEnabled: Bool = true, sizesToContent: Bool = true, onDismissRequest: @escaping () -> Void) {
        self.dismissEnabled = dismissEnabled
        self.sheetSwipeEnabled = sheetSwipeEnabled
        self.sizesToContent = sizesToContent
        self.onDismissRequest = onDismissRequest
        super.init(nibName: nil, bundle: nil)
        configurePresentation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yalla("background_base")
        buildScaffold()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasReportedContentHeight = false
        if sizesToContent {
            view.layoutIfNeeded()
            measuredHeight = preferredContentHeight()?.rounded()
        }
        applySheetPresentation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard sizesToContent,
              let h = preferredContentHeight()?.rounded(),
              h != measuredHeight else { return }
        measuredHeight = h
        if #available(iOS 16.0, *), let sheet = sheetPresentationController {
            sheet.animateChanges { sheet.invalidateDetents() }
        }
    }

    // MARK: - Content sizing

    func updateContentHeight(_ contentHeight: CGFloat) {
        // UIKit adds the bottom safe area to a custom detent automatically, so exclude it here.
        guard contentHeight.isFinite, contentHeight > 0 else { return }
        let chrome = headerHeightConstraint.constant
            + (footerZeroHeightConstraint.isActive ? 0 : Self.footerHeight)
        let total = (contentHeight + chrome).rounded()
        guard total != measuredHeight else { return }
        measuredHeight = total
        // Defer detent invalidation out of the current layout/CA transaction. Compose calls this
        // from inside its measure pass via onSizeChanged; calling invalidateDetents synchronously
        // there throws an NSException from UIKit, which K/N propagates as an unhandled Throwable.
        if #available(iOS 16.0, *) {
            let animate = hasReportedContentHeight
            hasReportedContentHeight = true
            DispatchQueue.main.async { [weak self] in
                guard let self, let sheet = self.sheetPresentationController else { return }
                if animate {
                    sheet.animateChanges { sheet.invalidateDetents() }
                } else {
                    sheet.invalidateDetents()
                }
            }
        }
    }

    func preferredContentHeight() -> CGFloat? { nil }

    // MARK: - Icon buttons

    func makeIconButton(icon: String, _ onTap: @escaping () -> Void) -> IconButtonHandle {
        YallaIconButtonFactory().create(
            icon: icon, shape: .circle, iconArgb: 0, containerArgb: 0, borderArgb: 0, onClick: onTap
        )
    }

    func makeCloseButton(_ onTap: @escaping () -> Void) -> IconButtonHandle {
        makeIconButton(icon: "ic_x", onTap)
    }

    func handleCloseTap() {
        onDismissRequest()
        dismiss(animated: true)
    }

    // MARK: - Slots

    func setHeader(title: String?, showClose: Bool, action actionVC: UIViewController? = nil, closeOnTrailing: Bool = false) {
        let hasContent = title != nil || showClose || actionVC != nil
        headerHeightConstraint.constant = hasContent ? Self.headerHeight : 0
        guard hasContent else { return }

        if showClose {
            let handle = makeCloseButton { [weak self] in self?.handleCloseTap() }
            closeHandle = handle
            addChild(handle.viewController)
            let closeView = handle.viewController.view!
            headerContainer.addSubview(closeView)
            pin(closeView, size: 44, top: 16)
            let edge = closeOnTrailing
                ? closeView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16)
                : closeView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16)
            edge.isActive = true
            handle.viewController.didMove(toParent: self)
        }

        if let title {
            titleLabel.text = title
            titleLabel.font = YallaFonts.Body.Large.medium.uiFont
            titleLabel.textColor = UIColor.yalla("text_base")
            titleLabel.textAlignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
                titleLabel.heightAnchor.constraint(equalToConstant: 44),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerContainer.leadingAnchor, constant: 60),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerContainer.trailingAnchor, constant: -60)
            ])
        }

        if let actionVC {
            addChild(actionVC)
            let actionView = actionVC.view!
            headerContainer.addSubview(actionView)
            pin(actionView, size: 44, top: 16)
            actionView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16).isActive = true
            actionVC.didMove(toParent: self)
        }
    }

    func setContent(_ content: UIView, controller: UIViewController? = nil, insets: UIEdgeInsets = .zero, centerVertically: Bool = false) {
        controller.map(addChild)
        content.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(content)
        var constraints = [
            content.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -insets.right),
            content.bottomAnchor.constraint(lessThanOrEqualTo: footerContainer.topAnchor, constant: -insets.bottom)
        ]
        if centerVertically {
            let band = UILayoutGuide()
            contentContainer.addLayoutGuide(band)
            constraints += [
                band.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
                band.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),
                content.topAnchor.constraint(greaterThanOrEqualTo: headerContainer.bottomAnchor, constant: insets.top),
                content.centerYAnchor.constraint(equalTo: band.centerYAnchor)
            ]
        } else {
            constraints.append(content.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: insets.top))
        }
        NSLayoutConstraint.activate(constraints)
        controller?.didMove(toParent: self)
    }

    func setFillContent(_ content: UIView, controller: UIViewController? = nil, insets: UIEdgeInsets? = nil) {
        controller.map(addChild)
        content.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(content)
        let resolved = insets ?? .zero
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: resolved.top),
            content.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: resolved.left),
            content.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -resolved.right),
            content.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -resolved.bottom)
        ])
        controller?.didMove(toParent: self)
    }

    func setScrollableContent(
        _ content: UIView,
        controller: UIViewController? = nil,
        insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    ) {
        controller.map(addChild)
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.delegate = self
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        contentContainer.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: insets.top),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -insets.right),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -insets.bottom),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(insets.left + insets.right))
        ])
        elevationScrollView = scrollView
        controller?.didMove(toParent: self)
    }

    func setFooter(_ footer: UIView, controller: UIViewController? = nil) {
        footerZeroHeightConstraint.isActive = false
        controller.map(addChild)
        footer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footer)
        NSLayoutConstraint.activate([
            footer.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: Self.footerInset),
            footer.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor, constant: Self.footerHorizontalInset),
            footer.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor, constant: -Self.footerHorizontalInset),
            footer.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -Self.footerInset),
            footer.heightAnchor.constraint(equalToConstant: Self.footerButtonHeight)
        ])
        controller?.didMove(toParent: self)
    }

    // MARK: - Scaffold

    private func buildScaffold() {
        headerContainer.backgroundColor = UIColor.yalla("background_base")
        footerContainer.backgroundColor = UIColor.yalla("background_base")
        footerContainer.layer.cornerRadius = 38
        footerContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        footerContainer.layer.masksToBounds = true
        contentContainer.clipsToBounds = true

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        [headerContainer, footerContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        configureShadow(headerContainer, yOffset: 3)
        configureShadow(footerContainer, yOffset: -3)

        headerHeightConstraint = headerContainer.heightAnchor.constraint(equalToConstant: 0)
        footerZeroHeightConstraint = footerContainer.heightAnchor.constraint(equalToConstant: 0)

        let footerSafeArea = footerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        footerSafeArea.priority = .defaultHigh

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightConstraint,

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor),
            footerSafeArea,
            footerZeroHeightConstraint
        ])
        view.bringSubviewToFront(headerContainer)
        view.bringSubviewToFront(footerContainer)
    }

    private func pin(_ subview: UIView, size: CGFloat, top: CGFloat) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: top),
            subview.widthAnchor.constraint(equalToConstant: size),
            subview.heightAnchor.constraint(equalToConstant: size)
        ])
    }

    private func configureShadow(_ container: UIView, yOffset: CGFloat) {
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: yOffset)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0
    }

    // MARK: - Elevation

    private func updateElevation() {
        guard let scrollView = elevationScrollView else { return }
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

    // MARK: - Presentation

    private func configurePresentation() {
        modalPresentationStyle = .pageSheet
        isModalInPresentation = !dismissEnabled || !sheetSwipeEnabled
    }

    private func applySheetPresentation() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }
        sheet.delegate = self
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 28
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        if #available(iOS 16.0, *) {
            sheet.detents = makeDetents()
            sheet.selectedDetentIdentifier = sizesToContent ? Self.contentDetentID : .large
        } else {
            sheet.detents = [.large()]
        }
    }

    @available(iOS 16.0, *)
    private func makeDetents() -> [UISheetPresentationController.Detent] {
        guard sizesToContent else { return [.large()] }
        let content = UISheetPresentationController.Detent.custom(identifier: Self.contentDetentID) { [weak self] context in
            guard let self, let h = self.measuredHeight else { return context.maximumDetentValue * 0.5 }
            return min(h, context.maximumDetentValue)
        }
        return [content]
    }
}

extension Sheet: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateElevation() }
}

extension Sheet: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if dismissEnabled { onDismissRequest() }
    }
}
