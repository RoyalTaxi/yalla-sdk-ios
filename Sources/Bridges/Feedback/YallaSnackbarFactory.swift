import UIKit
import YallaComponents

public final class YallaSnackbarFactory: NSObject, SnackbarFactory {
    private var window: UIWindow?
    private lazy var host: SnackbarHostController = {
        let controller = SnackbarHostController()
        controller.onEmpty = { [weak self] in self?.tearDownWindow() }
        return controller
    }()

    public override init() { super.init() }

    public func show(message: String, isError: Bool) {
        onMain { [weak self] in
            guard let self else { return }
            self.ensureWindow()
            self.host.enqueue(SnackbarItem(message: message, isError: isError))
        }
    }

    public func dismiss() {
        onMain { [weak self] in
            self?.host.dismissAll()
        }
    }

    private func ensureWindow() {
        if window != nil { return }
        guard let scene = UIApplication.activeBridgeWindowScene() else { return }
        let newWindow = PassthroughWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1
        newWindow.backgroundColor = .clear
        newWindow.rootViewController = host
        newWindow.isHidden = false
        self.window = newWindow
    }

    private func tearDownWindow() {
        guard let w = window else { return }
        w.windowScene = nil
        w.isHidden = true
        self.window = nil
    }
}
