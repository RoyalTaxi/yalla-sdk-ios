import UIKit
import Design

protocol SnackbarItemViewDelegate: AnyObject {
    func itemViewDidRequestDismiss(_ view: SnackbarItemView)
}

final class SnackbarItemView: UIView {
    weak var delegate: SnackbarItemViewDelegate?
    let item: SnackbarItem

    private let label = UILabel()
    private let closeButton = UIButton(type: .system)
    private var autoDismissWorkItem: DispatchWorkItem?

    init(item: SnackbarItem) {
        self.item = item
        super.init(frame: .zero)
        setUpUI()
        setUpGesture()
        scheduleAutoDismiss()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    deinit {
        autoDismissWorkItem?.cancel()
    }

    private func setUpUI() {
        backgroundColor = item.isError
            ? UIColor.yalla("border_error")
            : UIColor.yalla("background_brand")
        layer.cornerRadius = 12
        layer.masksToBounds = true

        label.text = item.message
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.yalla("text_white")
        label.font = YallaFonts.Body.Small.medium.uiFont

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor.yalla("icon_white")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        addSubview(label)
        addSubview(closeButton)

        label.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            label.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setUpGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    private func scheduleAutoDismiss() {
        let delay: TimeInterval = item.isError ? 5.0 : 3.0
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.delegate?.itemViewDidRequestDismiss(self)
        }
        autoDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    @objc private func closeTapped() {
        autoDismissWorkItem?.cancel()
        delegate?.itemViewDidRequestDismiss(self)
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: self)
        let velocity = pan.velocity(in: self)

        switch pan.state {
        case .changed:
            transform = CGAffineTransform(translationX: translation.x, y: 0)

        case .ended, .cancelled:
            let widthThreshold = bounds.width * 0.4
            let velocityThreshold: CGFloat = 500
            let shouldDismiss =
                abs(translation.x) > widthThreshold || abs(velocity.x) > velocityThreshold

            if shouldDismiss {
                autoDismissWorkItem?.cancel()
                let targetX: CGFloat = translation.x > 0 ? bounds.width : -bounds.width
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        self.transform = CGAffineTransform(translationX: targetX, y: 0)
                        self.alpha = 0
                    },
                    completion: { _ in
                        self.delegate?.itemViewDidRequestDismiss(self)
                    }
                )
            } else {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0,
                    options: []
                ) {
                    self.transform = .identity
                }
            }

        default:
            break
        }
    }
}
