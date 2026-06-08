import UIKit
import YallaComponents

final class SelectionSheet: Sheet {
    private let titleText: String
    private let items: [SelectableItemModel]
    private var selectedId: String?
    private let onSelect: (String) -> Void
    private let contentStack = UIStackView()
    private var rows: [(id: String, controller: SelectableItemController)] = []

    private let rowHeight: CGFloat = 56
    private let rowSpacing: CGFloat = 8
    private let contentInset: CGFloat = 12

    init(
        title: String,
        items: [SelectableItemModel],
        selectedId: String?,
        onSelect: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.titleText = title
        self.items = items
        self.selectedId = selectedId
        self.onSelect = onSelect
        super.init(dismissEnabled: true, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setHeader(title: titleText, showClose: true)
        buildItems()
        setScrollableContent(contentStack)
    }

    override func preferredContentHeight() -> CGFloat? {
        guard !items.isEmpty else { return nil }
        let rowsHeight = CGFloat(items.count) * rowHeight + CGFloat(items.count - 1) * rowSpacing
        return Sheet.headerHeight + rowsHeight + contentInset * 2
    }

    private func buildItems() {
        contentStack.axis = .vertical
        contentStack.spacing = rowSpacing
        for item in items {
            let controller = SelectableItemController(
                text: item.text,
                icon: item.icon,
                tintIcon: item.tintIcon,
                selected: item.id == selectedId,
                onClick: { [weak self] in self?.handleSelect(item.id) }
            )
            addChild(controller.viewController)
            let row = controller.viewController.view!
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            contentStack.addArrangedSubview(row)
            controller.viewController.didMove(toParent: self)
            rows.append((id: item.id, controller: controller))
        }
    }

    private func handleSelect(_ id: String) {
        selectedId = id
        for row in rows { row.controller.setSelected(selected: row.id == id) }
        onSelect(id)
    }
}
