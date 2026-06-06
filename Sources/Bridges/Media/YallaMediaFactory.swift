import UIKit
import PhotosUI
import YallaComponents

public final class YallaMediaFactory: NSObject, MediaFactory {
    public override init() { super.init() }

    // The picker controllers don't retain their delegates, so keep the active one alive until a
    // result arrives. Only one picker is presented at a time, so a single slot is enough.
    private var activeDelegate: NSObject?

    public func pickImages(selectionLimit: Int32, onResult: @escaping ([Data]) -> Void) {
        DispatchQueue.main.async {
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
            self.present(picker)
        }
    }

    public func captureImage(onResult: @escaping (Data?) -> Void) {
        DispatchQueue.main.async {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                onResult(nil)
                return
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
            self.present(picker)
        }
    }

    // MARK: - Native presentation

    private func present(_ viewController: UIViewController, attempt: Int = 0) {
        guard let root = Self.keyWindow()?.rootViewController else { return }

        if let presented = root.presentedViewController {
            if let coordinator = presented.transitionCoordinator {
                coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                    self?.present(viewController, attempt: attempt + 1)
                }
            } else if attempt < 60 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.present(viewController, attempt: attempt + 1)
                }
            }
            return
        }

        root.present(viewController, animated: true)
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }
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
