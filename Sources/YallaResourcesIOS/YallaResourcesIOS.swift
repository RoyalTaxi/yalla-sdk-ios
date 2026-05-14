import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Native iOS resource accessors generated from the canonical Yalla resources.
public enum YallaResourcesIOS {
    public static let bundle = Bundle.module

    public static func localizedString(
        _ key: String,
        tableName: String? = nil,
        value: String = "",
        comment: String = ""
    ) -> String {
        NSLocalizedString(
            key,
            tableName: tableName,
            bundle: bundle,
            value: value,
            comment: comment
        )
    }

    public static func imageAssetName(_ name: String) -> String {
        stripExtension(name, extension: "png")
    }

    #if canImport(UIKit)
    public static func platformImage(
        _ name: String,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIImage? {
        UIImage(
            named: imageAssetName(name),
            in: bundle,
            compatibleWith: traitCollection
        )
    }
    #elseif canImport(AppKit)
    public static func platformImage(_ name: String) -> NSImage? {
        bundle.image(forResource: NSImage.Name(imageAssetName(name)))
    }
    #endif

    @available(iOS 13.0, macOS 10.15, *)
    public static func swiftUIImage(_ name: String) -> Image {
        Image(imageAssetName(name), bundle: bundle)
    }

    public static func iconURL(_ name: String) -> URL? {
        resourceURL(name, withExtension: "svg", subdirectory: "Icons")
    }

    public static func fontURL(_ name: String) -> URL? {
        resourceURL(name, withExtension: "ttf", subdirectory: "Fonts")
    }

    public static func fileURL(_ name: String, withExtension fileExtension: String) -> URL? {
        resourceURL(name, withExtension: fileExtension, subdirectory: "Files")
    }

    private static func resourceURL(
        _ name: String,
        withExtension fileExtension: String,
        subdirectory: String
    ) -> URL? {
        let normalizedName = stripExtension(name, extension: fileExtension)
        return bundle.url(
            forResource: normalizedName,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) ?? bundle.url(
            forResource: normalizedName,
            withExtension: fileExtension
        )
    }

    private static func stripExtension(_ name: String, extension fileExtension: String) -> String {
        let suffix = ".\(fileExtension)"
        return name.hasSuffix(suffix) ? String(name.dropLast(suffix.count)) : name
    }
}
