import AVFoundation
import UIKit
import PhotosUI
import YallaComponents

/// The iOS native implementation of the Kotlin `MediaFactory` Compose↔native bridge protocol.
///
/// Presents the system photo-library and camera pickers and delivers the result back to Kotlin. Each
/// entry point resolves its `onResult` exactly once — including on every failure path — so the
/// fire-and-forget Kotlin caller never hangs. Only one picker may be in flight at a time.
public final class YallaMediaFactory: NSObject, MediaFactory {
    /// Creates the factory. Instantiated by the Kotlin bridge as the `MediaFactory` conformance.
    public override init() { super.init() }

    // The picker controllers don't retain their delegates, so keep the active one alive until a
    // result arrives. Only one picker is presented at a time, so a single slot is enough — concurrent
    // requests are rejected up front (see `pickImages`/`captureImage`) rather than clobbering it.
    private var activeDelegate: NSObject?

    /// Presents the system photo library and resolves `onResult` with the picked images' encoded data
    /// (empty if the user picks nothing). `selectionLimit` caps how many images may be selected
    /// (0 = unlimited). `onResult` is always called exactly once — including with `[]` if the picker
    /// can't be presented (no active window, a blocking modal that never frees) or while another
    /// picker is already in flight — so the caller never hangs.
    public func pickImages(selectionLimit: Int32, onResult: @escaping ([Data]) -> Void) {
        onMain {
            // Enforce the single-slot assumption: reject rather than overwrite the in-flight picker's
            // delegate (which would strand the first caller and dealloc the second's delegate).
            guard self.activeDelegate == nil else {
                onResult([])
                return
            }

            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = Int(selectionLimit)
            configuration.filter = .images

            // PHPickerViewController.delegate is `weak`. Retain the delegate strongly FIRST, or ARC
            // deallocates it right after assignment — then no selection callback ever fires and the
            // picker can't be dismissed / the image is never delivered.
            let delegate = PhotoPickerDelegate { [weak self] data in
                self?.activeDelegate = nil
                onResult(data)
            }
            self.activeDelegate = delegate

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = delegate
            self.present(picker) { [weak self] in
                self?.activeDelegate = nil
                onResult([])
            }
        }
    }

    /// Presents the system camera and resolves `onResult` with the captured image's JPEG data, or
    /// `nil` if the user cancels. `onResult` is always called exactly once — including with `nil` if
    /// the camera is unavailable, the picker can't be presented (no active window, a blocking modal
    /// that never frees), or while another picker is already in flight — so the caller never hangs.
    public func captureImage(onResult: @escaping (Data?) -> Void) {
        onMain {
            guard self.activeDelegate == nil else {
                onResult(nil)
                return
            }
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                onResult(nil)
                return
            }
            // `isSourceTypeAvailable` only reports hardware presence, not authorization. If access is
            // already denied/restricted, resolve a terminal result up front instead of presenting a
            // dead picker whose dismissal may not route through `imagePickerControllerDidCancel`.
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                onResult(nil)
                return
            default:
                break
            }
            // UIImagePickerController.delegate is `weak` — retain it strongly first (see pickImages).
            let delegate = CameraCaptureDelegate { [weak self] data in
                self?.activeDelegate = nil
                onResult(data)
            }
            self.activeDelegate = delegate

            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = false
            picker.delegate = delegate
            self.present(picker) { [weak self] in
                self?.activeDelegate = nil
                onResult(nil)
            }
        }
    }

    // MARK: - Native presentation

    /// Resolves a window to present from, then defers to the shared `presentSerialized` to wait out
    /// any in-flight transition / settled modal. `onUnavailable` is invoked (so the caller always
    /// gets a terminal result and the delegate slot is freed) if there is no window to present from
    /// or the presenter never frees within the cap.
    private func present(_ viewController: UIViewController, onUnavailable: @escaping () -> Void) {
        let windows = UIApplication.activeBridgeWindowScene()?.windows
        guard let root = (windows?.first(where: { $0.isKeyWindow }) ?? windows?.first)?.rootViewController else {
            onUnavailable()
            return
        }
        root.presentSerialized(viewController, animated: true, onGiveUp: onUnavailable)
    }
}

private final class PhotoPickerDelegate: NSObject, PHPickerViewControllerDelegate {
    private let onResult: ([Data]) -> Void

    init(onResult: @escaping ([Data]) -> Void) { self.onResult = onResult }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            onResult([])
            return
        }

        let group = DispatchGroup()
        var byIndex = [Int: Data]()
        let lock = NSLock()

        for (index, result) in results.enumerated() {
            group.enter()
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                if let data {
                    lock.lock(); byIndex[index] = data; lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [onResult] in
            let ordered = byIndex.sorted { $0.key < $1.key }.map { $0.value }
            onResult(ordered)
        }
    }
}

private final class CameraCaptureDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let onResult: (Data?) -> Void

    init(onResult: @escaping (Data?) -> Void) { self.onResult = onResult }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let image = info[.originalImage] as? UIImage
        onResult(image?.jpegData(compressionQuality: 1.0))
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        onResult(nil)
    }
}
