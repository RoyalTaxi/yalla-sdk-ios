import UIKit
import Design
import Resources
import YallaComponents

final class ConfirmationSheet: Sheet {
    private let imageName: String
    private let titleText: String
    private let descriptionText: String
    private let actionText: String
    private let onAction: () -> Void
    private let dismissEnabledFlag: Bool
    private let contentStack = UIStackView()

    init(
        imageResource: String,
        title: String,
        description: String,
        actionText: String,
        dismissEnabled: Bool,
        onAction: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.imageName = imageResource
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
        let buttonVC = PrimaryButtonKt.PrimaryButtonViewController(
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
        let header: CGFloat = dismissEnabledFlag ? 72 : 0
        // UIKit adds the bottom safe area to the custom detent — exclude it (header + insets 16+16 + content + footer 80).
        return header + 32 + fitting + 80
    }

    private func buildContent() -> UIView {
        let imageView = UIImageView()
        imageView.image = YallaResources.platformImage(imageName)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = YallaFonts.Title.base.uiFont
        titleLabel.textColor = UIColor.yalla("text_base")
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let descriptionLabel = UILabel()
        descriptionLabel.text = descriptionText
        descriptionLabel.font = YallaFonts.Body.Base.medium.uiFont
        descriptionLabel.textColor = UIColor.yalla("text_subtle")
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

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

}
