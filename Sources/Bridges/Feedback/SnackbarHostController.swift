import UIKit

final class SnackbarHostController: UIViewController, SnackbarItemViewDelegate {
    private let stackView = UIStackView()
    private var items: [SnackbarItemView] = []

    var onEmpty: (() -> Void)?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    func enqueue(_ item: SnackbarItem) {
        // The host knows the semantic type (the item view only colors itself); fire the matching
        // notification haptic here so success/error toasts feel native.
        if item.isError { Haptics.error() } else { Haptics.success() }

        let stale = items
        items.removeAll()

        let itemView = SnackbarItemView(item: item)
        itemView.delegate = self
        itemView.alpha = 0
        itemView.transform = CGAffineTransform(translationX: 0, y: -40)

        stackView.insertArrangedSubview(itemView, at: 0)
        items.insert(itemView, at: 0)

        stale.forEach { removeItemView($0, animated: true) }

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0,
            options: []
        ) {
            itemView.alpha = 1
            itemView.transform = .identity
        }
    }

    func dismissAll() {
        let snapshot = items
        items.removeAll()
        snapshot.forEach { removeItemView($0, animated: true) }
    }

    private func removeItemView(_ view: SnackbarItemView, animated: Bool) {
        let teardown = { [weak self, weak view] in
            guard let view else { return }
            view.removeFromSuperview()
            self?.items.removeAll { $0 === view }
            if self?.items.isEmpty == true {
                self?.onEmpty?()
            }
        }

        if animated {
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    view.alpha = 0
                    view.transform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
                },
                completion: { _ in teardown() }
            )
        } else {
            teardown()
        }
    }

    func itemViewDidRequestDismiss(_ view: SnackbarItemView) {
        removeItemView(view, animated: true)
    }
}
