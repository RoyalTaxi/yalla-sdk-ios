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
        setScrollableContent(buildContent(), insets: UIEdgeInsets(top: 14, left: 16, bottom: 16, right: 16))
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
        self.code = code
        self.descriptionText = description
        self.isError = isError
        self.isLoading = isLoading
        guard isViewLoaded else { return }

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

        let stack = UIStackView(arrangedSubviews: [headlineLabel, descriptionLabel, pinView, resendView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(10, after: headlineLabel)
        stack.setCustomSpacing(32, after: descriptionLabel)
        stack.setCustomSpacing(8, after: pinView)

        NSLayoutConstraint.activate([
            pinView.heightAnchor.constraint(equalTo: pinView.widthAnchor, multiplier: 1.0 / CGFloat(codeLength)),
            resendView.heightAnchor.constraint(equalToConstant: 44)
        ])
        return stack
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
        if newCode.count == codeLength { onCodeComplete(newCode) }
    }

    private func refreshConfirm() {
        confirmController.setEnabled(enabled: code.count == codeLength && !isError && !isLoading)
        confirmController.setLoading(loading: isLoading)
    }
}
