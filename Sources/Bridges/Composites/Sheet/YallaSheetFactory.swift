import UIKit
import YallaComponents

private final class ReusableSheet<T: UIViewController> {
    let viewController: T

    init(_ make: () -> T) {
        self.viewController = make()
    }

    func present(on parent: UIViewController) {
        onMain { parent.presentSerialized(self.viewController, animated: true) }
    }

    func dismiss() {
        onMain { self.viewController.dismiss(animated: true) }
    }
}

public final class YallaSheetFactory: NSObject, SheetFactory {
    public override init() { super.init() }

    public func createShell(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        contentController: UIViewController,
        onDismissRequest: @escaping () -> Void
    ) -> ContentSheetHandle {
        let reusable = ReusableSheet {
            ShellSheetController(
                fullHeight: fullHeight,
                sheetSwipeEnabled: sheetSwipeEnabled,
                contentController: contentController,
                onDismissRequest: onDismissRequest
            )
        }
        return ContentSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() },
            updateContentHeight: { height in onMain { reusable.viewController.updateComposeContentHeight(CGFloat(truncating: height)) } }
        )
    }

    public func createContent(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        title: String?,
        showClose: Bool,
        contentController: UIViewController,
        onClose: (() -> Void)?,
        onDismissRequest: @escaping () -> Void
    ) -> ContentSheetHandle {
        let reusable = ReusableSheet {
            ContentSheet(
                fullHeight: fullHeight,
                sheetSwipeEnabled: sheetSwipeEnabled,
                title: title,
                showClose: showClose,
                contentController: contentController,
                onClose: onClose,
                onDismissRequest: onDismissRequest
            )
        }
        return ContentSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() },
            updateContentHeight: { height in onMain { reusable.viewController.updateComposeContentHeight(CGFloat(truncating: height)) } }
        )
    }

    public func createConfirmation(
        imageResource: String,
        isDark: Bool,
        header: String?,
        title: String,
        description: String,
        actionText: String,
        dismissEnabled: Bool,
        onAction: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> ConfirmationSheetHandle {
        let reusable = ReusableSheet {
            ConfirmationSheet(imageResource: imageResource, isDark: isDark, header: header, title: title, description: description, actionText: actionText, dismissEnabled: dismissEnabled, onAction: onAction, onDismissRequest: onDismissRequest)
        }
        return ConfirmationSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() }
        )
    }

    public func createSelection(
        title: String,
        items: [SelectableItemModel],
        selectedId: String?,
        onSelect: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> SelectionSheetHandle {
        let reusable = ReusableSheet {
            SelectionSheet(title: title, items: items, selectedId: selectedId, onSelect: onSelect, onDismissRequest: onDismissRequest)
        }
        return SelectionSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() }
        )
    }

    public func createAction(
        title: String,
        items: [ActionableItemModel],
        onAction: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> ActionSheetHandle {
        let reusable = ReusableSheet {
            ActionSheet(title: title, items: items, onAction: onAction, onDismissRequest: onDismissRequest)
        }
        return ActionSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() }
        )
    }

    public func createDatePicker(
        startDate: Date,
        minDate: Date?,
        maxDate: Date?,
        title: String?,
        dismissEnabled: Bool,
        onSelect: @escaping (Date) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> DatePickerSheetHandle {
        let reusable = ReusableSheet {
            DatePickerSheet(startDate: startDate, minDate: minDate, maxDate: maxDate, title: title, dismissEnabled: dismissEnabled, onSelect: onSelect, onDismissRequest: onDismissRequest)
        }
        return DatePickerSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() }
        )
    }

    public func createVerification(
        code: String,
        codeLength: Int32,
        headline: String,
        description: String,
        confirmText: String,
        resendText: String,
        title: String?,
        isError: Bool,
        isLoading: Bool,
        resendEnabled: Bool,
        dismissEnabled: Bool,
        alphanumeric: Bool,
        onCodeChange: @escaping (String) -> Void,
        onConfirm: @escaping () -> Void,
        onResend: @escaping () -> Void,
        onCodeComplete: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> VerificationSheetHandle {
        let viewController = VerificationSheet(
            code: code,
            codeLength: Int(codeLength),
            headline: headline,
            description: description,
            confirmText: confirmText,
            resendText: resendText,
            title: title,
            isError: isError,
            isLoading: isLoading,
            resendEnabled: resendEnabled,
            dismissEnabled: dismissEnabled,
            alphanumeric: alphanumeric,
            onCodeChange: onCodeChange,
            onConfirm: onConfirm,
            onResend: onResend,
            onCodeComplete: onCodeComplete,
            onDismissRequest: onDismissRequest
        )

        return VerificationSheetHandle(
            viewController: viewController,
            present: { [weak viewController] parent in
                onMain {
                    guard let viewController else { return }
                    parent.presentSerialized(viewController, animated: true)
                }
            },
            update: { [weak viewController] code, description, isError, isLoading, resendText, resendEnabled in
                onMain {
                    viewController?.update(
                        code: code,
                        description: description,
                        isError: isError.boolValue,
                        isLoading: isLoading.boolValue,
                        resendText: resendText,
                        resendEnabled: resendEnabled.boolValue
                    )
                }
            },
            dismiss: { [weak viewController] in
                onMain { viewController?.dismiss(animated: true) }
            }
        )
    }

}
