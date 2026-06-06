import SwiftUI
import Resources

public struct TextButton: View {
    public let text: String
    public let contentColor: Color?
    public let containerColor: Color?
    public let onClick: () -> Void

    public init(
        _ text: String,
        contentColor: Color? = nil,
        containerColor: Color? = nil,
        onClick: @escaping () -> Void
    ) {
        self.text = text
        self.contentColor = contentColor
        self.containerColor = containerColor
        self.onClick = onClick
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(text, action: onClick)
                .buttonStyle(.glass)
                .clipShape(Capsule())
                .tint(containerColor)
                .foregroundStyle(contentColor ?? .secondary)
        } else {
            Button(text, action: onClick)
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
                .tint(containerColor)
                .foregroundStyle(contentColor ?? .secondary)
        }
    }
}

#Preview {
    TextButton(
        "Resend",
        contentColor: Color("text_subtle", bundle: YallaResources.bundle),
        containerColor: Color("background_secondary", bundle: YallaResources.bundle),
        onClick: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("background_base", bundle: YallaResources.bundle))
}
