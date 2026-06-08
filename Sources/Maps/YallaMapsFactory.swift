import Foundation
import GoogleMaps
import YallaComponents

public final class YallaMapsFactory: NSObject, IosMapRendererFactory {

    private let libreStyleURL: String

    public init(libreStyleURL: String? = nil) {
        self.libreStyleURL = libreStyleURL ?? MapConstants.shared.LIGHT_STYLE_URL
        super.init()
        Self.provideGoogleApiKeyOnce()
    }

    public func createGoogleRenderer() -> any IosMapRenderer {
        GoogleMapRenderer()
    }

    public func createLibreRenderer() -> any IosMapRenderer {
        LibreMapRenderer(styleURL: libreStyleURL)
    }

    private static let lock = NSLock()
    private static var provided = false

    // Mirrors Android: the key is baked into the bundle at build time (Info.plist ←
    // GOOGLE_MAPS_API_KEY xcconfig, exactly as Android injects the manifest placeholder
    // from local.properties). The app never passes the key in code.
    private static func provideGoogleApiKeyOnce() {
        lock.lock()
        defer { lock.unlock() }
        if provided { return }
        provided = true
        let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String
        if let key, !key.isEmpty {
            GMSServices.provideAPIKey(key)
        }
    }
}
