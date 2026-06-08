import UIKit
import YallaComponents

final class ContentSheet: Sheet {
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
