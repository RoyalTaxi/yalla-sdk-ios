import UIKit
import Design
import YallaComponents

final class ContentSheet: Sheet {
    private let titleText: String?
    private let showClose: Bool
    private let contentController: UIViewController
    private var composeContentHeight: CGFloat = 0
    private var hasHeader: Bool { titleText != nil || showClose }

    init(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        title: String?,
        showClose: Bool,
        contentController: UIViewController,
        onDismissRequest: @escaping () -> Void
    ) {
        self.titleText = title
        self.showClose = showClose
        self.contentController = contentController
        super.init(dismissEnabled: true, sheetSwipeEnabled: sheetSwipeEnabled, sizesToContent: !fullHeight, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: showClose)
        setFillContent(
            contentController.view,
            controller: contentController,
            insets: UIEdgeInsets(top: hasHeader ? Sheet.headerHeight : 0, left: 0, bottom: 0, right: 0)
        )
    }

    override func preferredContentHeight() -> CGFloat? {
        guard composeContentHeight > 0 else { return nil }
        return composeContentHeight + (hasHeader ? Sheet.headerHeight : 0)
    }

    func updateComposeContentHeight(_ height: CGFloat) {
        composeContentHeight = height
        updateContentHeight(height)
    }
}

final class PromoCodeSheet: Sheet {
    private let titleText: String
    private let headlineText: String
    private let placeholderText: String
    private let hintText: String
    private let confirmTitle: String
    private let onCodeChangeCallback: (String) -> Void
    private let onSubmit: () -> Void

    private var code: String
    private var isLoading: Bool
    private let contentStack = UIStackView()
    private let contentTopInset: CGFloat = 32
    private let contentBottomInset: CGFloat = 16

    private lazy var fieldController = PrimaryFieldController(
        value: code,
        placeholder: placeholderText,
        enabled: true,
        centered: true,
        autoFocus: true,
        onValueChange: { [weak self] newCode in self?.handleCodeChange(newCode) }
    )
    private lazy var confirmController = PrimaryButtonController(
        text: confirmTitle,
        enabled: !code.isEmpty && !isLoading,
        loading: isLoading,
        onClick: onSubmit
    )

    init(
        code: String,
        title: String,
        headline: String,
        placeholder: String,
        hint: String,
        confirmText: String,
        isLoading: Bool,
        onCodeChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.code = code
        self.titleText = title
        self.headlineText = headline
        self.placeholderText = placeholder
        self.hintText = hint
        self.confirmTitle = confirmText
        self.isLoading = isLoading
        self.onCodeChangeCallback = onCodeChange
        self.onSubmit = onSubmit
        super.init(dismissEnabled: true, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: true)
        setScrollableContent(buildContent(), insets: UIEdgeInsets(top: contentTopInset, left: 20, bottom: contentBottomInset, right: 20))
        fieldController.viewController.didMove(toParent: self)
        setFooter(confirmController.viewController.view, controller: confirmController.viewController)
    }

    override func preferredContentHeight() -> CGFloat? {
        let width = max(view.bounds.width - 40, 1)
        let fitting = contentStack.systemLayoutSizeFitting(
            CGSize(width: width, height: .greatestFiniteMagnitude),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return Sheet.headerHeight + contentTopInset + fitting + contentBottomInset + Sheet.footerHeight
    }

    func update(code: String, isLoading: Bool) {
        self.code = code
        self.isLoading = isLoading
        guard isViewLoaded else { return }
        fieldController.setValue(value: code)
        confirmController.setLoading(loading: isLoading)
        confirmController.setEnabled(enabled: !code.isEmpty && !isLoading)
    }

    private func buildContent() -> UIView {
        let headlineLabel = UILabel()
        headlineLabel.text = headlineText
        headlineLabel.font = YallaFonts.Title.large.uiFont
        headlineLabel.textColor = UIColor.yalla("text_base")
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 0

        let hintLabel = UILabel()
        hintLabel.text = hintText
        hintLabel.font = YallaFonts.Body.Base.medium.uiFont
        hintLabel.textColor = UIColor.yalla("text_subtle")
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        addChild(fieldController.viewController)
        let fieldView = fieldController.viewController.view!
        fieldView.translatesAutoresizingMaskIntoConstraints = false
        fieldView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.addArrangedSubview(headlineLabel)
        contentStack.addArrangedSubview(fieldView)
        contentStack.addArrangedSubview(hintLabel)
        contentStack.setCustomSpacing(34, after: headlineLabel)
        contentStack.setCustomSpacing(34, after: fieldView)
        return contentStack
    }

    private func handleCodeChange(_ newCode: String) {
        code = newCode
        confirmController.setEnabled(enabled: !newCode.isEmpty && !isLoading)
        onCodeChangeCallback(newCode)
    }
}

final class NotificationDetailSheet: Sheet {
    private let titleText: String
    private let dateText: String
    private let bodyText: String
    private let imageUrlText: String?

    private let imageView = UIImageView()
    private let imageHeightConstraint: NSLayoutConstraint
    private var loadingTask: URLSessionDataTask?
    private let contentStack = UIStackView()
    private let contentInset: CGFloat = 16

    init(
        title: String,
        date: String,
        body: String,
        imageUrl: String?,
        onDismissRequest: @escaping () -> Void
    ) {
        self.titleText = title
        self.dateText = date
        self.bodyText = body
        self.imageUrlText = imageUrl
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
        super.init(dismissEnabled: true, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: nil, showClose: true)
        setScrollableContent(buildContent(), insets: UIEdgeInsets(top: 8, left: contentInset, bottom: contentInset, right: contentInset))
        if let url = imageUrlText, !url.isEmpty {
            loadImage(from: url)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let sheet = self.sheetPresentationController else { return }
            sheet.animateChanges { sheet.invalidateDetents() }
        }
    }

    override func preferredContentHeight() -> CGFloat? {
        guard contentStack.bounds.width > 0 else { return nil }
        contentStack.layoutIfNeeded()
        let height = contentStack.bounds.height > 0
            ? contentStack.bounds.height
            : contentStack.systemLayoutSizeFitting(
                CGSize(width: contentStack.bounds.width, height: .greatestFiniteMagnitude),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        return Sheet.headerHeight + 8 + height + contentInset
    }

    private func buildContent() -> UIView {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageHeightConstraint.isActive = true

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = YallaFonts.Body.Base.bold.uiFont
        titleLabel.textColor = UIColor.yalla("text_base")
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        let dateLabel = UILabel()
        dateLabel.text = dateText
        dateLabel.font = YallaFonts.Body.Base.regular.uiFont
        dateLabel.textColor = UIColor.yalla("text_subtle")
        dateLabel.textAlignment = .right
        dateLabel.numberOfLines = 1
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        headerRow.axis = .horizontal
        headerRow.alignment = .firstBaseline
        headerRow.spacing = 12
        headerRow.distribution = .fill

        let divider = UIView()
        divider.backgroundColor = UIColor.yalla("border_disabled") ?? UIColor(white: 0.85, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let bodyLabel = UILabel()
        bodyLabel.text = bodyText
        bodyLabel.font = YallaFonts.Body.Base.regular.uiFont
        bodyLabel.textColor = UIColor.yalla("text_base")
        bodyLabel.numberOfLines = 0

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(divider)
        contentStack.addArrangedSubview(bodyLabel)
        contentStack.setCustomSpacing(16, after: imageView)
        contentStack.setCustomSpacing(12, after: headerRow)
        contentStack.setCustomSpacing(12, after: divider)
        if imageUrlText?.isEmpty != false {
            contentStack.setCustomSpacing(0, after: imageView)
        }
        return contentStack
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        loadingTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
                let aspect = image.size.height / max(image.size.width, 1)
                let width = self.view.bounds.width - 32
                self.imageHeightConstraint.constant = (width * aspect).rounded()
                self.view.setNeedsLayout()
                if #available(iOS 16.0, *), let sheet = self.sheetPresentationController {
                    sheet.animateChanges { sheet.invalidateDetents() }
                }
            }
        }
        loadingTask?.resume()
    }

    deinit {
        loadingTask?.cancel()
    }
}

final class AddCardSheet: Sheet {
    private let titleText: String
    private let confirmTitle: String
    private let cardNumberPlaceholder: String
    private let expiryPlaceholder: String
    private let onCardNumberChange: (String) -> Void
    private let onExpiryChange: (String) -> Void
    private let onSubmit: () -> Void

    private var cardNumber: String
    private var cardExpiry: String
    private var isError: Bool
    private var isLoading: Bool
    private let contentStack = UIStackView()
    private let contentTopInset: CGFloat = 12
    private let contentBottomInset: CGFloat = 16

    private lazy var cardNumberController = CardFieldController(
        value: cardNumber,
        placeholder: cardNumberPlaceholder,
        mask: .cardNumber,
        isError: isError,
        showScanIcon: true,
        onValueChange: { [weak self] new in self?.handleCardNumberChange(new) }
    )
    private lazy var expiryController = CardFieldController(
        value: cardExpiry,
        placeholder: expiryPlaceholder,
        mask: .expiry,
        isError: isError,
        showScanIcon: false,
        onValueChange: { [weak self] new in self?.handleExpiryChange(new) }
    )
    private lazy var confirmController = PrimaryButtonController(
        text: confirmTitle,
        enabled: isConfirmEnabled,
        loading: isLoading,
        onClick: onSubmit
    )

    init(
        cardNumber: String,
        cardExpiry: String,
        title: String,
        cardNumberPlaceholder: String,
        expiryPlaceholder: String,
        confirmText: String,
        isError: Bool,
        isLoading: Bool,
        onCardNumberChange: @escaping (String) -> Void,
        onExpiryChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.cardNumber = cardNumber
        self.cardExpiry = cardExpiry
        self.titleText = title
        self.confirmTitle = confirmText
        self.cardNumberPlaceholder = cardNumberPlaceholder
        self.expiryPlaceholder = expiryPlaceholder
        self.isError = isError
        self.isLoading = isLoading
        self.onCardNumberChange = onCardNumberChange
        self.onExpiryChange = onExpiryChange
        self.onSubmit = onSubmit
        super.init(dismissEnabled: true, onDismissRequest: onDismissRequest)
    }

    private var isConfirmEnabled: Bool { cardNumber.count == 16 && cardExpiry.count == 4 && !isLoading }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: true)
        setScrollableContent(buildContent(), insets: UIEdgeInsets(top: contentTopInset, left: 20, bottom: contentBottomInset, right: 20))
        cardNumberController.viewController.didMove(toParent: self)
        expiryController.viewController.didMove(toParent: self)
        setFooter(confirmController.viewController.view, controller: confirmController.viewController)
    }

    override func preferredContentHeight() -> CGFloat? {
        let width = max(view.bounds.width - 40, 1)
        let fitting = contentStack.systemLayoutSizeFitting(
            CGSize(width: width, height: .greatestFiniteMagnitude),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return Sheet.headerHeight + contentTopInset + fitting + contentBottomInset + Sheet.footerHeight
    }

    func update(cardNumber: String, cardExpiry: String, isError: Bool, isLoading: Bool) {
        self.cardNumber = cardNumber
        self.cardExpiry = cardExpiry
        self.isError = isError
        self.isLoading = isLoading
        guard isViewLoaded else { return }
        cardNumberController.setValue(value: cardNumber)
        cardNumberController.setError(isError: isError)
        expiryController.setValue(value: cardExpiry)
        expiryController.setError(isError: isError)
        confirmController.setLoading(loading: isLoading)
        confirmController.setEnabled(enabled: isConfirmEnabled)
    }

    private func buildContent() -> UIView {
        addChild(cardNumberController.viewController)
        addChild(expiryController.viewController)
        let cardView = cardNumberController.viewController.view!
        let expiryView = expiryController.viewController.view!
        cardView.translatesAutoresizingMaskIntoConstraints = false
        expiryView.translatesAutoresizingMaskIntoConstraints = false
        cardView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        expiryView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 12
        contentStack.addArrangedSubview(cardView)
        contentStack.addArrangedSubview(expiryView)
        return contentStack
    }

    private func handleCardNumberChange(_ new: String) {
        cardNumber = new
        confirmController.setEnabled(enabled: isConfirmEnabled)
        onCardNumberChange(new)
    }

    private func handleExpiryChange(_ new: String) {
        cardExpiry = new
        confirmController.setEnabled(enabled: isConfirmEnabled)
        onExpiryChange(new)
    }
}

final class ShellSheetController: Sheet {
    private let contentController: UIViewController
    private var composeContentHeight: CGFloat = 0

    init(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        contentController: UIViewController,
        onDismissRequest: @escaping () -> Void
    ) {
        self.contentController = contentController
        super.init(dismissEnabled: true, sheetSwipeEnabled: sheetSwipeEnabled, sizesToContent: !fullHeight, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setFillContent(contentController.view, controller: contentController)
    }

    override func preferredContentHeight() -> CGFloat? {
        composeContentHeight > 0 ? composeContentHeight : nil
    }

    func updateComposeContentHeight(_ height: CGFloat) {
        composeContentHeight = height
        updateContentHeight(height)
    }
}
