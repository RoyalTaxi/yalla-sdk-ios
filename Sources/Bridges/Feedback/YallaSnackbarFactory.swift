import UIKit
import YallaComponents

/// The iOS native implementation of the Kotlin `SnackbarFactory` Compose↔native bridge protocol.
///
/// Snackbars are hosted in a dedicated passthrough window above the app's content so they float over
/// any presented sheet; the window is created on demand and torn down once the last toast clears.
public final class YallaSnackbarFactory: NSObject, SnackbarFactory {
    private var window: UIWindow?
    private lazy var host: SnackbarHostController = {
        let controller = SnackbarHostController()
        controller.onEmpty = { [weak self] in self?.tearDownWindow() }
        return controller
    }()

    /// Creates the factory. Instantiated by the Kotlin bridge as the `SnackbarFactory` conformance.
    public override init() { super.init() }

    /// Shows a transient toast. `isError` selects the error styling and the matching haptic.
    /// Safe to call from any thread.
    public func show(message: String, isError: Bool) {
        onMain { [weak self] in
            guard let self else { return }
            self.ensureWindow()
            self.host.enqueue(SnackbarItem(message: message, isError: isError))
        }
    }

    /// Dismisses all visible toasts. Safe to call from any thread.
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
