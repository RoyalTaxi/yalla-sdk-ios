import UIKit
import Resources
import YallaComponents

enum MapIconLoader {

    private static let cache = NSCache<NSString, UIImage>()

    static let userLocationDotImage: UIImage = {
        let size = CGSize(width: 16, height: 16)
        let strokeWidth: CGFloat = 2 / UIScreen.main.scale
        // Brand violet (0x562DF8) so the dot matches the accuracy circle drawn around it; a slightly
        // darker stop gives subtle depth. Shared by both the Google and MapLibre renderers.
        let start = UIColor(red: 0x56 / 255.0, green: 0x2D / 255.0, blue: 0xF8 / 255.0, alpha: 1)
        let end = UIColor(red: 0x3D / 255.0, green: 0x1F / 255.0, blue: 0xB0 / 255.0, alpha: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let top = CGPoint(x: size.width / 2, y: 0)
            let bottom = CGPoint(x: size.width / 2, y: size.height)
            if let fill = CGGradient(colorsSpace: colorSpace, colors: [start.cgColor, end.cgColor] as CFArray, locations: [0, 1]) {
                ctx.saveGState()
                ctx.addEllipse(in: rect)
                ctx.clip()
                ctx.drawLinearGradient(fill, start: top, end: bottom, options: [])
                ctx.restoreGState()
            }
            if let stroke = CGGradient(colorsSpace: colorSpace, colors: [end.cgColor, start.cgColor] as CFArray, locations: [0, 1]) {
                ctx.saveGState()
                ctx.setLineWidth(strokeWidth)
                ctx.addEllipse(in: rect)
                ctx.replacePathWithStrokedPath()
                ctx.clip()
                ctx.drawLinearGradient(stroke, start: top, end: bottom, options: [])
                ctx.restoreGState()
            }
        }
    }()

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
        } else if let dot = icon as? MapMarkerIcon.Dot {
            image = dotImage(for: dot)
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

    private static func dotImage(for dot: MapMarkerIcon.Dot) -> UIImage {
        let strokeWidth = CGFloat(dot.strokeWidthDp)
        let side = CGFloat(dot.diameterDp) + strokeWidth
        let size = CGSize(width: side, height: side)
        let fillColor = UIColor(argb: dot.fillColorArgb)
        let strokeColor = UIColor(argb: dot.strokeColorArgb)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)
            fillColor.setFill()
            context.cgContext.fillEllipse(in: rect)
            strokeColor.setStroke()
            context.cgContext.setLineWidth(strokeWidth)
            context.cgContext.strokeEllipse(in: rect)
        }
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

        let ringColor = UIColor(argb: pin.colorArgb)

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
        if let dot = icon as? MapMarkerIcon.Dot { return "dot-\(dot.fillColorArgb)-\(dot.strokeColorArgb)-\(dot.diameterDp)-\(dot.strokeWidthDp)" }
        if let bytes = icon as? MapMarkerIcon.Bytes {
            return "bytes-\(bytesDigest(bytes.data))"
        }
        return "unknown"
    }

    /// Stable content digest for a `Bytes` icon's payload: `<length>-<FNV-1a hash of the bytes>`.
    ///
    /// `KotlinByteArray.hashValue` is identity/address-derived, NOT a content hash — it is unstable
    /// across runs (the same PNG churns the cache after a relaunch) AND collidable, so two different
    /// PNGs could share a key and serve the wrong cached bitmap. Hashing length + content makes the key
    /// deterministic per payload and collision-resistant. `internal` so the no-collision property can
    /// be pinned by tests.
    static func bytesDigest(_ array: KotlinByteArray) -> String {
        let count = Int(array.size)
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325 // FNV-1a 64-bit offset basis
        for i in 0..<count {
            hash ^= UInt64(UInt8(bitPattern: array.get(index: Int32(i))))
            hash = hash &* 0x0000_0100_0000_01B3 // FNV-1a 64-bit prime
        }
        return "\(count)-\(String(hash, radix: 16))"
    }
}
