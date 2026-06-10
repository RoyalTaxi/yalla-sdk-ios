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
        } else if let pin = icon as? MapMarkerIcon.Pin {
            image = pinImage(for: pin)
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

    private static func pinImage(for pin: MapMarkerIcon.Pin) -> UIImage {
        let markerSize: CGFloat = 22
        let ringWidth: CGFloat = 6
        let badgeHeight: CGFloat = 28
        let badgePadding: CGFloat = 12
        let label = (pin.label as String?).flatMap { $0.isEmpty ? nil : $0 }

        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
        let textSize = label.map { ($0 as NSString).size(withAttributes: attributes) } ?? .zero
        let badgeWidth = label != nil ? textSize.width + badgePadding * 2 : 0

        let width = max(markerSize, badgeWidth)
        let height = label != nil ? badgeHeight * 2 + markerSize : markerSize
        let size = CGSize(width: width, height: height)

        let ringColor = UIColor(
            red: CGFloat((pin.colorArgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((pin.colorArgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(pin.colorArgb & 0xFF) / 255.0,
            alpha: CGFloat((pin.colorArgb >> 24) & 0xFF) / 255.0
        )

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let centerX = width / 2
            let circleTop = label != nil ? badgeHeight : 0
            let circleRect = CGRect(x: centerX - markerSize / 2, y: circleTop, width: markerSize, height: markerSize)

            if let label {
                let badgeRect = CGRect(x: centerX - badgeWidth / 2, y: 0, width: badgeWidth, height: badgeHeight)
                let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeHeight / 2)
                UIColor(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0, alpha: 1).setFill()
                badgePath.fill()
                let textOrigin = CGPoint(
                    x: badgeRect.midX - textSize.width / 2,
                    y: badgeRect.midY - textSize.height / 2
                )
                (label as NSString).draw(at: textOrigin, withAttributes: attributes)
            }

            ringColor.setFill()
            context.cgContext.fillEllipse(in: circleRect)
            let innerInset = ringWidth
            let innerRect = circleRect.insetBy(dx: innerInset, dy: innerInset)
            if innerRect.width > 0 {
                UIColor.white.setFill()
                context.cgContext.fillEllipse(in: innerRect)
            }
        }
    }

    private static func cacheKey(for icon: MapMarkerIcon) -> String {
        if let res = icon as? MapMarkerIcon.Resource { return "res-\(res.name)" }
        if let pin = icon as? MapMarkerIcon.Pin { return "pin-\(pin.colorArgb)-\(pin.label ?? "")" }
        if let bytes = icon as? MapMarkerIcon.Bytes {
            return "bytes-\(bytes.data.hashValue)"
        }
        return "unknown"
    }
}
