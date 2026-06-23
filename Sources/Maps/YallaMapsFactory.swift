import Foundation
import GoogleMaps
import YallaComponents

public final class YallaMapsFactory: NSObject, IosMapRendererFactory {

    private let libreStyleURL: String

    public init(libreStyleURL: String? = nil) {
        self.libreStyleURL = libreStyleURL ?? MapStyle.companion.CARTO.lightUrl
        super.init()
        Self.provideGoogleApiKeyOnce()
    }

    public func createGoogleRenderer() -> any IosMapRenderer {
        GoogleMapRenderer(routeFollowingEnabled: true)
    }

    public func createLibreRenderer() -> any IosMapRenderer {
        LibreMapRenderer(styleURL: libreStyleURL, routeFollowingEnabled: true)
    }

    private static let lock = NSLock()
    private static var provided = false

    private static func provideGoogleApiKeyOnce() {
        lock.lock()
        defer { lock.unlock() }
        if provided { return }
        provided = true
        let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String
        if let key, !key.isEmpty {
            GMSServices.provideAPIKey(key)
        } else {
            NSLog("[YallaMaps] GOOGLE_MAPS_API_KEY missing or empty in Info.plist; the Google backend will render blank. Set it via the GOOGLE_MAPS_API_KEY xcconfig.")
        }
    }
}
