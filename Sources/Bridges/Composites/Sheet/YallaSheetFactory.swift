import UIKit
import YallaComponents

/// Holds a single sheet wrapper for the whole lifetime of the Compose controller it wraps and
/// re-presents that same instance on every show.
///
/// The wrapper is built once and never recreated. The factory sheets wrap a long-lived
/// `ComposeUIViewController` created once on the Kotlin side (it lives for the whole composable
/// lifetime) and add it as a child VC in `viewDidLoad`. Recreating the wrapper on re-present would
/// `addChild` that already-parented controller without first detaching it from the previous wrapper
/// — undefined UIKit that renders a blank / asserting sheet on the common dismiss-then-re-show path.
/// Reusing the one wrapper also keeps `viewController` stable, so a handle that captured it (and the
/// Kotlin `onFullyExpanded` poll that reads `handle.viewController.isBeingPresented()`) always sees
/// the live, currently-presented controller rather than a discarded snapshot.
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

/// The iOS native implementation of the Kotlin `SheetFactory` Compose↔native bridge protocol.
///
/// Each `create*` method builds a native sheet view controller and returns an imperative
/// `*Handle` of closures (`present`/`dismiss`/`update*`) the Kotlin side drives. The handle's
/// `viewController` is the live, reused sheet — stable across re-presents. All handle closures are
/// marshalled to the main thread, so the bridge is safe regardless of the caller's queue.
public final class YallaSheetFactory: NSObject, SheetFactory {
    /// Creates the factory. Instantiated by the Kotlin bridge as the `SheetFactory` conformance.
    public override init() { super.init() }

    /// A bare sheet that hosts `contentController` edge-to-edge (no header/footer chrome), sizing to
    /// the Compose content's reported height.
    /// - Parameters:
    ///   - fullHeight: present at the large detent instead of sizing to content.
    ///   - sheetSwipeEnabled: allow interactive swipe-to-dismiss.
    ///   - contentController: the Compose-hosting controller to embed; reused across re-presents.
    ///   - onDismissRequest: fired when the sheet is dismissed (swipe or programmatic close).
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

    /// A sheet that hosts `contentController` under an optional title/close-button header.
    /// - Parameters:
    ///   - fullHeight: present at the large detent instead of sizing to content.
    ///   - sheetSwipeEnabled: allow interactive swipe-to-dismiss.
    ///   - title: optional header title; `nil` hides the title.
    ///   - showClose: show a close button in the header.
    ///   - contentController: the Compose-hosting controller to embed; reused across re-presents.
    ///   - onClose: the caller's explicit close action, fired when the header close button is tapped
    ///     (distinct from `onDismissRequest`, which fires on any dismissal). `nil` if unset.
    ///   - onDismissRequest: fired when the sheet is dismissed (swipe, backdrop, or close button).
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

    /// A confirmation sheet: an illustration, header/title/description text, and a single action button.
    /// - Parameters:
    ///   - imageResource: an asset-catalog image name in the SDK resource bundle (not a URL).
    ///   - isDark: render with the dark-mode illustration/colors regardless of system appearance.
    ///   - header: optional small header above the title.
    ///   - actionText: label for the primary action button.
    ///   - dismissEnabled: allow swipe/backdrop dismissal.
    ///   - onAction: fired when the action button is tapped.
    ///   - onDismissRequest: fired when the sheet is dismissed without invoking the action.
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

    /// A single-select list sheet.
    /// - Parameters:
    ///   - items: the selectable rows.
    ///   - selectedId: the id of the initially-selected row, if any.
    ///   - onSelect: fired with the selected row's id when the user picks a row.
    ///   - onDismissRequest: fired when the sheet is dismissed without a selection.
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

    /// An action-list sheet (a menu of tappable rows that each fire and dismiss).
    /// - Parameters:
    ///   - items: the action rows.
    ///   - onAction: fired with the tapped row's id.
    ///   - onDismissRequest: fired when the sheet is dismissed without tapping an action.
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

    /// A date-picker sheet.
    /// - Parameters:
    ///   - startDate: the initially-selected date.
    ///   - minDate: optional earliest selectable date.
    ///   - maxDate: optional latest selectable date.
    ///   - dismissEnabled: allow swipe/backdrop dismissal.
    ///   - onSelect: fired with the chosen date when the user confirms.
    ///   - onDismissRequest: fired when the sheet is dismissed without confirming.
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

    /// An OTP/verification-code sheet with a fixed-length code field and resend affordance.
    /// - Parameters:
    ///   - code: the initial code value.
    ///   - codeLength: number of digits the code field expects.
    ///   - isError: render the field in its error state (e.g. a rejected code).
    ///   - isLoading: show the confirm button's loading state.
    ///   - resendEnabled: enable the resend action.
    ///   - dismissEnabled: allow swipe/backdrop dismissal.
    ///   - alphanumeric: accept letters as well as digits and show an ASCII keyboard instead of the
    ///     numeric keypad (mirrors the shared `PinField`'s `alphanumeric` flag).
    ///   - onCodeChange: fired on every code edit.
    ///   - onConfirm: fired when the confirm button is tapped.
    ///   - onResend: fired when resend is tapped.
    ///   - onCodeComplete: fired once the full `codeLength` is entered.
    ///   - onDismissRequest: fired when the sheet is dismissed.
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

    /// A promo-code entry sheet with a single text field and submit button.
    /// - Parameters:
    ///   - code: the initial field value.
    ///   - placeholder: the field's placeholder text.
    ///   - hint: helper text shown under the field.
    ///   - isLoading: show the submit button's loading state.
    ///   - onCodeChange: fired on every edit.
    ///   - onSubmit: fired when submit is tapped.
    ///   - onDismissRequest: fired when the sheet is dismissed.
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
                onMain {
                    guard let viewController else { return }
                    parent.presentSerialized(viewController, animated: true)
                }
            },
            update: { [weak viewController] code, isLoading in
                onMain { viewController?.update(code: code, isLoading: isLoading.boolValue) }
            },
            dismiss: { [weak viewController] in
                onMain { viewController?.dismiss(animated: true) }
            }
        )
    }

    /// An add-payment-card sheet with masked card-number and expiry fields.
    /// - Parameters:
    ///   - cardNumber: the initial (unmasked) card-number value.
    ///   - cardExpiry: the initial expiry value (MMYY).
    ///   - isError: render both fields in their error state.
    ///   - isLoading: show the submit button's loading state.
    ///   - onCardNumberChange: fired on every card-number edit.
    ///   - onExpiryChange: fired on every expiry edit.
    ///   - onSubmit: fired when submit is tapped.
    ///   - onDismissRequest: fired when the sheet is dismissed.
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
                onMain {
                    guard let viewController else { return }
                    parent.presentSerialized(viewController, animated: true)
                }
            },
            update: { [weak viewController] cardNumber, cardExpiry, isError, isLoading in
                onMain {
                    viewController?.update(
                        cardNumber: cardNumber,
                        cardExpiry: cardExpiry,
                        isError: isError.boolValue,
                        isLoading: isLoading.boolValue
                    )
                }
            },
            dismiss: { [weak viewController] in
                onMain { viewController?.dismiss(animated: true) }
            }
        )
    }

    /// A notification-detail sheet showing a title, date, body, and an optional remote image.
    /// - Parameters:
    ///   - imageUrl: an optional remote image URL; the image slot collapses if absent or the load fails.
    ///   - onDismissRequest: fired when the sheet is dismissed.
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
                onMain {
                    guard let viewController else { return }
                    parent.presentSerialized(viewController, animated: true)
                }
            },
            dismiss: { [weak viewController] in
                onMain { viewController?.dismiss(animated: true) }
            }
        )
    }
}
