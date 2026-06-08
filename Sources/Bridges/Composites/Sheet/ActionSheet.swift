import UIKit
import YallaComponents

final class ActionSheet: Sheet {
    private let titleText: String
    private let items: [ActionableItemModel]
    private let onAction: (String) -> Void
    private let contentStack = UIStackView()

    init(
        title: String,
        items: [ActionableItemModel],
        onAction: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.titleText = title
        self.items = items
        self.onAction = onAction
        super.init(dismissEnabled: true, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: true)
        buildItems()
        setContent(contentStack, insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
    }

    override func preferredContentHeight() -> CGFloat? {
        guard !items.isEmpty else { return nil }
        let rows = CGFloat(items.count) * 64 + CGFloat(items.count - 1) * 10
        return 72 + rows + 24
    }

    private func buildItems() {
        contentStack.axis = .vertical
        contentStack.spacing = 10
        for item in items {
            let controller = ActionableItemController(
                text: item.text,
                icon: item.icon,
                trailingIcon: item.trailingIcon,
                isDestructive: item.isDestructive,
                onClick: { [weak self] in self?.onAction(item.id) }
            )
            addChild(controller.viewController)
            let row = controller.viewController.view!
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(equalToConstant: 64).isActive = true
            contentStack.addArrangedSubview(row)
            controller.viewController.didMove(toParent: self)
        }
    }
}
