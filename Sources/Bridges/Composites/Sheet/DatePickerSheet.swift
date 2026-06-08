import UIKit
import YallaComponents

final class DatePickerSheet: Sheet {
    private let datePicker = UIDatePicker()
    private lazy var doneButton = makeIconButton(icon: "ic_check") { [weak self] in self?.confirmSelection() }

    private let initialDate: Date
    private let minimumDateValue: Date?
    private let maximumDateValue: Date?
    private let titleText: String?
    private let onSelect: (Date) -> Void
    private let dismissEnabledFlag: Bool

    init(
        startDate: Date,
        minDate: Date?,
        maxDate: Date?,
        title: String?,
        dismissEnabled: Bool,
        onSelect: @escaping (Date) -> Void,
        onDismissRequest: @escaping () -> Void
    ) {
        self.initialDate = startDate
        self.minimumDateValue = minDate
        self.maximumDateValue = maxDate
        self.titleText = title
        self.onSelect = onSelect
        self.dismissEnabledFlag = dismissEnabled
        super.init(dismissEnabled: dismissEnabled, onDismissRequest: onDismissRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDatePicker()
        setHeader(title: titleText, showClose: dismissEnabledFlag, action: doneButton.viewController)
        setContent(datePicker, insets: Self.contentInsets)
    }

    override func preferredContentHeight() -> CGFloat? {
        Sheet.headerHeight + Self.contentInsets.top + Self.contentInsets.bottom + datePicker.intrinsicContentSize.height
    }

    private static let contentInsets = UIEdgeInsets(top: 20, left: 16, bottom: 16, right: 16)

    private func setUpDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.timeZone = TimeZone(identifier: "UTC")
        datePicker.date = initialDate
        datePicker.minimumDate = minimumDateValue
        datePicker.maximumDate = maximumDateValue
    }

    private func confirmSelection() {
        onSelect(datePicker.date)
        dismiss(animated: true)
    }
}
