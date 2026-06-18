import UIKit
import YallaComponents

private final class ReusableSheet<T: UIViewController> {
    private let make: () -> T
    private var reuseFirst = true
    private(set) var viewController: T

    init(_ make: @escaping () -> T) {
        self.make = make
        self.viewController = make()
    }

    func present(on parent: UIViewController) {
        if reuseFirst { reuseFirst = false } else { viewController = make() }
        parent.presentSerialized(viewController, animated: true)
    }

    func dismiss() {
        viewController.dismiss(animated: true)
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
            updateContentHeight: { reusable.viewController.updateComposeContentHeight(CGFloat(truncating: $0)) }
        )
    }

    public func createContent(
        fullHeight: Bool,
        sheetSwipeEnabled: Bool,
        title: String?,
        showClose: Bool,
        contentController: UIViewController,
        onDismissRequest: @escaping () -> Void
    ) -> ContentSheetHandle {
        let reusable = ReusableSheet {
            ContentSheet(
                fullHeight: fullHeight,
                sheetSwipeEnabled: sheetSwipeEnabled,
                title: title,
                showClose: showClose,
                contentController: contentController,
                onDismissRequest: onDismissRequest
            )
        }
        return ContentSheetHandle(
            viewController: reusable.viewController,
            present: { reusable.present(on: $0) },
            dismiss: { reusable.dismiss() },
            updateContentHeight: { reusable.viewController.updateComposeContentHeight(CGFloat(truncating: $0)) }
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
                parent.presentSerialized(viewController, animated: true)
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

    public func createPromoCode(
        code: String,
        title: String,
        headline: String,
        placeholder: String,
        hint: String,
        confirmText: String,
        isLoading: Bool,
        onCodeChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> PromoCodeSheetHandle {
        let viewController = PromoCodeSheet(
            code: code,
            title: title,
            headline: headline,
            placeholder: placeholder,
            hint: hint,
            confirmText: confirmText,
            isLoading: isLoading,
            onCodeChange: onCodeChange,
            onSubmit: onSubmit,
            onDismissRequest: onDismissRequest
        )
        return PromoCodeSheetHandle(
            viewController: viewController,
            present: { [weak viewController] parent in
                guard let viewController else { return }
                parent.presentSerialized(viewController, animated: true)
            },
            update: { [weak viewController] code, isLoading in
                viewController?.update(code: code, isLoading: isLoading.boolValue)
            },
            dismiss: { [weak viewController] in
                viewController?.dismiss(animated: true)
            }
        )
    }

    public func createAddCard(
        cardNumber: String,
        cardExpiry: String,
        title: String,
        cardNumberPlaceholder: String,
        expiryPlaceholder: String,
        confirmText: String,
        isError: Bool,
        isLoading: Bool,
        onCardNumberChange: @escaping (String) -> Void,
        onExpiryChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        onDismissRequest: @escaping () -> Void
    ) -> AddCardSheetHandle {
        let viewController = AddCardSheet(
            cardNumber: cardNumber,
            cardExpiry: cardExpiry,
            title: title,
            cardNumberPlaceholder: cardNumberPlaceholder,
            expiryPlaceholder: expiryPlaceholder,
            confirmText: confirmText,
            isError: isError,
            isLoading: isLoading,
            onCardNumberChange: onCardNumberChange,
            onExpiryChange: onExpiryChange,
            onSubmit: onSubmit,
            onDismissRequest: onDismissRequest
        )
        return AddCardSheetHandle(
            viewController: viewController,
            present: { [weak viewController] parent in
                guard let viewController else { return }
                parent.presentSerialized(viewController, animated: true)
            },
            update: { [weak viewController] cardNumber, cardExpiry, isError, isLoading in
                viewController?.update(
                    cardNumber: cardNumber,
                    cardExpiry: cardExpiry,
                    isError: isError.boolValue,
                    isLoading: isLoading.boolValue
                )
            },
            dismiss: { [weak viewController] in
                viewController?.dismiss(animated: true)
            }
        )
    }

    public func createNotificationDetail(
        title: String,
        date: String,
        body: String,
        imageUrl: String?,
        onDismissRequest: @escaping () -> Void
    ) -> NotificationDetailSheetHandle {
        let viewController = NotificationDetailSheet(
            title: title,
            date: date,
            body: body,
            imageUrl: imageUrl,
            onDismissRequest: onDismissRequest
        )
        return NotificationDetailSheetHandle(
            viewController: viewController,
            present: { [weak viewController] parent in
                guard let viewController else { return }
                parent.presentSerialized(viewController, animated: true)
            },
            dismiss: { [weak viewController] in
                viewController?.dismiss(animated: true)
            }
        )
    }
}

private extension UIViewController {
    /// Presents `vc`, first waiting out any in-flight transition of whatever this controller is
    /// already presenting. iOS refuses to present while the presenter is mid-transition — exactly
    /// what breaks sheet-to-sheet swaps: the coordinator dismisses the outgoing sheet and presents
    /// the incoming one in the same frame, so the new present lands while the old sheet is still
    /// animating out and is silently dropped (and on iOS 26 can throw).
    ///
    /// It never force-dismisses the current occupant: the outgoing sheet's own lifecycle dismisses
    /// it, so we only WAIT for the presenter to free up — chaining off the in-flight transition's
    /// coordinator, or polling a frame when something settled still occupies it. That avoids tearing
    /// down an unrelated modal (alert / share / Safari) that happens to be up. The attempt cap stops
    /// it spinning if the presenter never frees (e.g. a modal that's staying put).
    func presentSerialized(_ vc: UIViewController, animated: Bool, attempt: Int = 0) {
        if vc.presentingViewController != nil { return } // already presented — don't double-present
        guard let presented = presentedViewController else {
            present(vc, animated: animated)
            return
        }
        guard attempt < 60 else { return } // give up rather than fight an unexpected modal
        if let coordinator = presented.transitionCoordinator {
            // A transition (the outgoing sheet's dismiss) is in flight — present once it completes.
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1)
            }
        } else {
            // Something settled still occupies the presenter — in a swap this is the outgoing sheet
            // a frame before its own dismiss runs. Wait a hop and retry; never dismiss it ourselves.
            DispatchQueue.main.async { [weak self] in
                self?.presentSerialized(vc, animated: animated, attempt: attempt + 1)
            }
        }
    }
}
