import UIKit
import Design
import Resources
import YallaComponents

final class ConfirmationSheet: Sheet {
    private let imageName: String
    private let isDarkAppearance: Bool
    private let titleText: String
    private let descriptionText: String
    private let actionText: String
    private let onAction: () -> Void
    private let dismissEnabledFlag: Bool
    private let contentStack = UIStackView()

    private let contentVerticalInset: CGFloat = 32
    private let detentBottomSlack: CGFloat = 16

    init(
        imageResource: String,
        isDark: Bool,
        title: String,
        description: String,
        actionText: String,
        dismissEnabled: Bool,
        onAction: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.imageName = imageResource
        self.isDarkAppearance = isDark
        self.titleText = title
        self.descriptionText = description
        self.actionText = actionText
        self.onAction = onAction
        self.dismissEnabledFlag = dismissEnabled
        super.init(dismissEnabled: dismissEnabled, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: nil, showClose: dismissEnabledFlag)
        setContent(
            buildContent(),
            insets: UIEdgeInsets(top: 16, left: 36, bottom: 16, right: 36),
            centerVertically: true
        )
        let buttonVC = PrimaryButton_iosKt.PrimaryButtonViewController(
            title: actionText,
            onClick: { [weak self] in self?.onAction() }
        )
        setFooter(buttonVC.view, controller: buttonVC)
    }

    override func preferredContentHeight() -> CGFloat? {
        let fitting = contentStack.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width - 72, height: .greatestFiniteMagnitude),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let header: CGFloat = dismissEnabledFlag ? Sheet.headerHeight : 0
        return header + contentVerticalInset + fitting + Sheet.footerHeight + detentBottomSlack
    }

    private func buildContent() -> UIView {
        let imageView = UIImageView()
        let traits = UITraitCollection(userInterfaceStyle: isDarkAppearance ? .dark : .light)
        imageView.image = YallaResources.platformImage(imageName, compatibleWith: traits)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = centeredLabel(
            text: titleText,
            font: YallaFonts.Title.base.uiFont,
            color: UIColor.yalla("text_base")
        )
        let descriptionLabel = centeredLabel(
            text: descriptionText,
            font: YallaFonts.Body.Base.medium.uiFont,
            color: UIColor.yalla("text_subtle")
        )

        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 12
        contentStack.setCustomSpacing(36, after: imageView)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            descriptionLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
        return contentStack
    }

    private func centeredLabel(text: String, font: UIFont, color: UIColor?) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}
