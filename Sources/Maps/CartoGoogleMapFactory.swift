import Foundation
import YallaComponents

public final class CartoGoogleMapFactory: NSObject, GoogleIosRendererFactory {
    public func create(camera: GoogleIosCamera, minZoom: Float, maxZoom: Float) -> any GoogleIosMapRenderer {
        CartoGoogleMapRenderer(camera: camera, minZoom: minZoom, maxZoom: maxZoom)
    }
}
