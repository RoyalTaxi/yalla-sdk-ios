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
        setContent(datePicker, insets: UIEdgeInsets(top: 20, left: 16, bottom: 16, right: 16))
    }

    override func preferredContentHeight() -> CGFloat? {
        // UIKit adds the bottom safe area to the custom detent — exclude it (header + insets 20+16 + picker).
        72 + (20 + 16) + datePicker.intrinsicContentSize.height
    }

    private func setUpDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.timeZone = TimeZone(identifier: "UTC")
        datePicker.date = initialDate
        if let minimumDateValue { datePicker.minimumDate = minimumDateValue }
        if let maximumDateValue { datePicker.maximumDate = maximumDateValue }
    }

    private func confirmSelection() {
        onSelect(datePicker.date)
        dismiss(animated: true)
    }
}
