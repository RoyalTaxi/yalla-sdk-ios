import UIKit

final class ContentSheet: Sheet {
    private let titleText: String?
    private let showClose: Bool
    private let contentController: UIViewController
    private let onClose: (() -> Void)?
    private var composeContentHeight: CGFloat = 0
    private var hasHeader: Bool { titleText != nil || showClose }

    init(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        title: String?,
        showClose: Bool,
        contentController: UIViewController,
        onClose: (() -> Void)?,
        onDismissRequest: @escaping () -> Void
    ) {
        self.titleText = title
        self.showClose = showClose
        self.contentController = contentController
        self.onClose = onClose
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

    override func handleCloseTap() {
        onClose?()
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
