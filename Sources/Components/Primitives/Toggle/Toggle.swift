import SwiftUI

public struct Toggle: View {
    public let checked: Bool
    public let onCheckedChange: (Bool) -> Void
    public let enabled: Bool
    public let tintColor: Color?

    public init(
        checked: Bool,
        enabled: Bool = true,
        tintColor: Color? = nil,
        onCheckedChange: @escaping (Bool) -> Void
    ) {
        self.checked = checked
        self.enabled = enabled
        self.tintColor = tintColor
        self.onCheckedChange = onCheckedChange
    }

    public var body: some View {
        SwiftUI.Toggle("", isOn: Binding(
            get: { checked },
            set: { onCheckedChange($0) }
        ))
        .labelsHidden()
        .disabled(!enabled)
        .tint(tintColor)
    }
}

#Preview {
    Toggle(checked: true, onCheckedChange: { _ in })
}
