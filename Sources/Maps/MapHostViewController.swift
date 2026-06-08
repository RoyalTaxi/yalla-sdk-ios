import UIKit

final class MapHostViewController: UIViewController {

    private let mapSubview: UIView

    init(mapSubview: UIView) {
        self.mapSubview = mapSubview
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapSubview.translatesAutoresizingMaskIntoConstraints = false
        if mapSubview.superview !== view {
            mapSubview.removeFromSuperview()
            view.addSubview(mapSubview)
        }
        NSLayoutConstraint.activate([
            mapSubview.topAnchor.constraint(equalTo: view.topAnchor),
            mapSubview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapSubview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapSubview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
