import UIKit
import YallaComponents

final class ActionSheet: Sheet {
    private let titleText: String
    private let items: [ActionableItemModel]
    private let onAction: (String) -> Void
    private let contentStack = UIStackView()

    private let rowHeight: CGFloat = 64
    private let rowSpacing: CGFloat = 10
    private let contentInset: CGFloat = 12

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
        setScrollableContent(contentStack, insets: UIEdgeInsets(top: contentInset, left: 16, bottom: contentInset, right: 16))
    }

    override func preferredContentHeight() -> CGFloat? {
        guard !items.isEmpty else { return nil }
        let rows = CGFloat(items.count) * rowHeight + CGFloat(items.count - 1) * rowSpacing
        return Sheet.headerHeight + rows + contentInset * 2
    }

    private func buildItems() {
        contentStack.axis = .vertical
        contentStack.spacing = rowSpacing
        for item in items {
            let controller = ActionableItemController(
                text: item.text,
                icon: item.icon,
                trailingIcon: item.trailingIcon,
                isDestructive: item.isDestructive,
                onClick: { [weak self] in
                    if item.isDestructive { Haptics.warning() } else { Haptics.impact(.light) }
                    self?.onAction(item.id)
                }
            )
            addChild(controller.viewController)
            let row = controller.viewController.view!
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            contentStack.addArrangedSubview(row)
            controller.viewController.didMove(toParent: self)
        }
    }
}
