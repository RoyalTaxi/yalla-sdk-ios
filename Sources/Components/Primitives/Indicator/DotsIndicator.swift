import SwiftUI
import UIKit

public struct DotsIndicator: UIViewRepresentable {
    public let pageCount: Int
    public let currentPage: Int
    public let onPageChange: (Int) -> Void

    public init(pageCount: Int, currentPage: Int, onPageChange: @escaping (Int) -> Void) {
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.onPageChange = onPageChange
    }

    public func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.backgroundStyle = .prominent
        pageControl.allowsContinuousInteraction = true
        pageControl.addAction(
            UIAction { [weak pageControl] _ in
                onPageChange(pageControl?.currentPage ?? 0)
            },
            for: .valueChanged
        )
        return pageControl
    }

    public func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = pageCount
        uiView.currentPage = currentPage
    }
}

#Preview {
    StatefulPreviewWrapper(1) { current in
        DotsIndicator(
            pageCount: 4,
            currentPage: current.wrappedValue,
            onPageChange: { current.wrappedValue = $0 }
        )
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
