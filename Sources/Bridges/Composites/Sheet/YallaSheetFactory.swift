import UIKit
import YallaComponents

public final class YallaSheetFactory: NSObject, SheetFactory {
    public override init() { super.init() }

    public func createConfirmation(
        imageResource: String,
        title: String,
        description: String,
        actionText: String,
        dismissEnabled: Bool,
        onAction: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> ConfirmationSheetHandle {
        // Fresh VC per (re-)present — see createAction. Reusing one VC carries stale sheet state.
        let make = { ConfirmationSheet(imageResource: imageResource, title: title, description: description, actionText: actionText, dismissEnabled: dismissEnabled, onAction: onAction, onDismissRequest: onDismissRequest) }
        var current = make()
        var reuseFirst = true

        return ConfirmationSheetHandle(
            viewController: current,
            present: { parent in
                if reuseFirst { reuseFirst = false } else { current = make() }
                parent.present(current, animated: true)
            },
            dismiss: {
                current.dismiss(animated: true)
            }
        )
    }

    public func createSelection(
        title: String,
        items: [SelectableItemModel],
        selectedId: String?,
        onSelect: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> SelectionSheetHandle {
        // Fresh VC per (re-)present — see createAction. Reusing one VC carries stale sheet state.
        let make = { SelectionSheet(title: title, items: items, selectedId: selectedId, onSelect: onSelect, onDismissRequest: onDismissRequest) }
        var current = make()
        var reuseFirst = true

        return SelectionSheetHandle(
            viewController: current,
            present: { parent in
                if reuseFirst { reuseFirst = false } else { current = make() }
                parent.present(current, animated: true)
            },
            dismiss: {
                current.dismiss(animated: true)
            }
        )
    }

    public func createAction(
        title: String,
        items: [ActionableItemModel],
        onAction: @escaping (String) -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> ActionSheetHandle {
        let make = { ActionSheet(title: title, items: items, onAction: onAction, onDismissRequest: onDismissRequest) }
        var current = make()
        var reuseFirst = true

        return ActionSheetHandle(
            viewController: current,
            present: { parent in
                // Fresh VC per (re-)present: the binding remembers one handle, so reusing the same
                // VC carries its UISheetPresentationController's stale gesture/detent state into the
                // next open (jump to a previously-dragged height). A new instance starts clean.
                if reuseFirst { reuseFirst = false } else { current = make() }
                parent.present(current, animated: true)
            },
            dismiss: {
                current.dismiss(animated: true)
            }
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
        // Fresh VC per (re-)present — see createAction. Reusing one VC carries stale sheet state.
        let make = { DatePickerSheet(startDate: startDate, minDate: minDate, maxDate: maxDate, title: title, dismissEnabled: dismissEnabled, onSelect: onSelect, onDismissRequest: onDismissRequest) }
        var current = make()
        var reuseFirst = true

        return DatePickerSheetHandle(
            viewController: current,
            present: { parent in
                if reuseFirst { reuseFirst = false } else { current = make() }
                parent.present(current, animated: true)
            },
            dismiss: {
                current.dismiss(animated: true)
            }
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
            onCodeChange: onCodeChange,
            onConfirm: onConfirm,
            onResend: onResend,
            onCodeComplete: onCodeComplete,
            onDismissRequest: onDismissRequest
        )

        return VerificationSheetHandle(
            viewController: viewController,
            present: { [weak viewController] parent in
                guard let viewController else { return }
                parent.present(viewController, animated: true)
            },
            update: { [weak viewController] code, description, isError, isLoading, resendText, resendEnabled in
                viewController?.update(
                    code: code,
                    description: description,
                    isError: isError.boolValue,
                    isLoading: isLoading.boolValue,
                    resendText: resendText,
                    resendEnabled: resendEnabled.boolValue
                )
            },
            dismiss: { [weak viewController] in
                viewController?.dismiss(animated: true)
            }
        )
    }
}
