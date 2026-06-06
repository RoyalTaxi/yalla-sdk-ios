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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.ensureWindow()
            self.host.enqueue(SnackbarItem(message: message, isError: isError))
        }
    }

    public func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.host.dismissAll()
        }
    }

    private func ensureWindow() {
        if window != nil { return }
        guard let scene = activeWindowScene() else { return }
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

    private func activeWindowScene() -> UIWindowScene? {
        let priorityFor: (UIScene.ActivationState) -> Int = { state in
            switch state {
            case .foregroundActive: return 0
            case .foregroundInactive: return 1
            case .background: return 2
            case .unattached: return 3
            @unknown default: return 4
            }
        }
        return UIApplication.shared.connectedScenes
            .sorted { priorityFor($0.activationState) < priorityFor($1.activationState) }
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
