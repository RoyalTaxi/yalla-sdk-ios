import UIKit
import Resources
import YallaComponents

enum MapIconLoader {

    private static let cache = NSCache<NSString, UIImage>()

    static func uiImage(for icon: MapMarkerIcon) -> UIImage? {
        let key = cacheKey(for: icon) as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let image: UIImage?
        if let resource = icon as? MapMarkerIcon.Resource {
            image = YallaResources.platformIcon(resource.name)
                ?? YallaResources.platformImage(resource.name)
                ?? UIImage(named: resource.name)
        } else if let bytes = icon as? MapMarkerIcon.Bytes {
            let kotlinArray = bytes.data
            let count = Int(kotlinArray.size)
            var buffer = Data(count: count)
            for i in 0..<count {
                buffer[i] = UInt8(bitPattern: kotlinArray.get(index: Int32(i)))
            }
            image = UIImage(data: buffer)
        } else {
            image = nil
        }
        if let resolved = image { cache.setObject(resolved, forKey: key) }
        return image
    }

    private static func cacheKey(for icon: MapMarkerIcon) -> String {
        if let res = icon as? MapMarkerIcon.Resource { return "res-\(res.name)" }
        if let bytes = icon as? MapMarkerIcon.Bytes {
            return "bytes-\(bytes.data.hashValue)"
        }
        return "unknown"
    }
}
