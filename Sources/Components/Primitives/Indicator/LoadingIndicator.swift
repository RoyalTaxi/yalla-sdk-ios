import SwiftUI
import UIKit

public struct LoadingIndicator: UIViewRepresentable {
    public let color: UIColor?

    public init(color: UIColor? = nil) {
        self.color = color
    }

    public func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = color
        indicator.startAnimating()
        return indicator
    }

    public func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.color = color
    }
}

#Preview {
    LoadingIndicator()
}
