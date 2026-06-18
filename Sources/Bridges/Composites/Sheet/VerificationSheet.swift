import UIKit
import Design
import YallaComponents

final class VerificationSheet: Sheet {
    private let codeLength: Int
    private let onCodeChangeCallback: (String) -> Void
    private let onConfirm: () -> Void
    private let onCodeComplete: (String) -> Void

    private let titleText: String?
    private let headlineText: String
    private var descriptionText: String
    private let descriptionLabel = UILabel()
    private let dismissEnabledFlag: Bool

    private var code: String
    private var isError: Bool
    private var isLoading: Bool

    private let confirmTitle: String
    private let onResend: () -> Void
    private let initialResendText: String
    private let initialResendEnabled: Bool

    private lazy var pinController = PinFieldController(
        length: Int32(codeLength),
        code: code,
        error: isError,
        autoFocus: true,
        horizontalPadding: 16,
        onValueChange: { [weak self] newCode in self?.handleCodeChange(newCode) }
    )
    private lazy var resendController = GhostButtonController(
        text: initialResendText,
        enabled: initialResendEnabled && !isLoading,
        onClick: onResend
    )
    private lazy var confirmController = PrimaryButtonController(
        text: confirmTitle,
        enabled: isConfirmEnabled,
        loading: isLoading,
        onClick: onConfirm
    )

    init(
        code: String,
        codeLength: Int,
        headline: String,
        description: String,
        confirmText: String,
        resendText: String,
        title: String?,
        isError: Bool,
        isLoading: Bool,
        resendEnabled: Bool,
        dismissEnabled: Bool,
        onCodeChange: @escaping (String) -> Void,
        onConfirm: @escaping () -> Void,
        onResend: @escaping () -> Void,
        onCodeComplete: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.code = code
        self.codeLength = codeLength
        self.headlineText = headline
        self.descriptionText = description
        self.confirmTitle = confirmText
        self.initialResendText = resendText
        self.initialResendEnabled = resendEnabled
        self.titleText = title
        self.isError = isError
        self.isLoading = isLoading
        self.dismissEnabledFlag = dismissEnabled
        self.onCodeChangeCallback = onCodeChange
        self.onConfirm = onConfirm
        self.onResend = onResend
        self.onCodeComplete = onCodeComplete
        // Opt out of content-sizing: this sheet always wants .large() for the keyboard + pin field.
        super.init(dismissEnabled: dismissEnabled, sizesToContent: false, onDismissRequest: onDismissRequest)
    }

    private var isConfirmEnabled: Bool { code.count == codeLength && !isError && !isLoading }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: dismissEnabledFlag)
        setScrollableContent(buildContent(), insets: UIEdgeInsets(top: 14, left: 0, bottom: 16, right: 0))
        pinController.viewController.didMove(toParent: self)
        resendController.viewController.didMove(toParent: self)
        setFooter(confirmController.viewController.view, controller: confirmController.viewController)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshConfirm()
    }

    func update(
        code: String,
        description: String,
        isError: Bool,
        isLoading: Bool,
        resendText: String,
        resendEnabled: Bool
    ) {
        let wasError = self.isError
        self.code = code
        self.descriptionText = description
        self.isError = isError
        self.isLoading = isLoading
        guard isViewLoaded else { return }

        // Fire the error haptic only on the no-error -> error edge so re-renders don't re-buzz.
        if !wasError && isError { Haptics.error() }

        descriptionLabel.text = description
        pinController.setCode(code: code)
        pinController.setError(error: isError)
        resendController.setText(text: resendText)
        resendController.setEnabled(enabled: resendEnabled && !isLoading)
        refreshConfirm()
    }

    private func buildContent() -> UIView {
        let headlineLabel = UILabel()
        configureLabel(headlineLabel, text: headlineText, font: YallaFonts.Title.base.uiFont, color: UIColor.yalla("text_base"))
        configureLabel(descriptionLabel, text: descriptionText, font: YallaFonts.Body.Base.medium.uiFont, color: UIColor.yalla("text_subtle"))

        addChild(pinController.viewController)
        addChild(resendController.viewController)
        let pinView = pinController.viewController.view!
        let resendView = resendController.viewController.view!
        pinView.translatesAutoresizingMaskIntoConstraints = false
        resendView.translatesAutoresizingMaskIntoConstraints = false

        let headlineContainer = inset(headlineLabel, horizontal: 16)
        let descriptionContainer = inset(descriptionLabel, horizontal: 16)
        let resendContainer = inset(resendView, horizontal: 16)

        let stack = UIStackView(arrangedSubviews: [headlineContainer, descriptionContainer, pinView, resendContainer])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(10, after: headlineContainer)
        stack.setCustomSpacing(32, after: descriptionContainer)
        stack.setCustomSpacing(8, after: pinView)

        NSLayoutConstraint.activate([
            pinView.heightAnchor.constraint(
                equalTo: pinView.widthAnchor,
                multiplier: 1.0 / CGFloat(codeLength),
                constant: -32.0 / CGFloat(codeLength)
            ),
            resendView.heightAnchor.constraint(equalToConstant: 44)
        ])
        return stack
    }

    private func inset(_ view: UIView, horizontal: CGFloat) -> UIView {
        let container = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontal),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontal),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func configureLabel(_ label: UILabel, text: String, font: UIFont, color: UIColor?) {
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
    }

    private func handleCodeChange(_ newCode: String) {
        code = newCode
        refreshConfirm()
        onCodeChangeCallback(newCode)
        if newCode.count == codeLength {
            Haptics.success()
            onCodeComplete(newCode)
        }
    }

    private func refreshConfirm() {
        confirmController.setEnabled(enabled: code.count == codeLength && !isError && !isLoading)
        confirmController.setLoading(loading: isLoading)
    }
}
