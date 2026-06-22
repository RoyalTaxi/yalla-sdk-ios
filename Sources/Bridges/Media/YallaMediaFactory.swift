import AVFoundation
import UIKit
import PhotosUI
import YallaComponents

public final class YallaMediaFactory: NSObject, MediaFactory {
    public override init() { super.init() }

    private var activeDelegate: NSObject?

    public func pickImages(selectionLimit: Int32, onResult: @escaping ([Data]) -> Void) {
        onMain {
            guard self.activeDelegate == nil else {
                onResult([])
                return
            }

            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = Int(selectionLimit)
            configuration.filter = .images

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
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                onResult(nil)
                return
            default:
                break
            }
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
