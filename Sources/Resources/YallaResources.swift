import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum YallaResources {
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

    public static func iconAssetName(_ name: String) -> String {
        stripExtension(name, extension: "svg")
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

    public static func platformIcon(
        _ name: String,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIImage? {
        UIImage(
            named: iconAssetName(name),
            in: bundle,
            compatibleWith: traitCollection
        )
    }
    #elseif canImport(AppKit)
    public static func platformImage(_ name: String) -> NSImage? {
        bundle.image(forResource: NSImage.Name(imageAssetName(name)))
    }

    public static func platformIcon(_ name: String) -> NSImage? {
        bundle.image(forResource: NSImage.Name(iconAssetName(name)))
    }
    #endif

    @available(iOS 13.0, macOS 10.15, *)
    public static func swiftUIImage(_ name: String) -> Image {
        Image(imageAssetName(name), bundle: bundle)
    }

    @available(iOS 13.0, macOS 10.15, *)
    public static func swiftUIIcon(_ name: String) -> Image {
        Image(iconAssetName(name), bundle: bundle)
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
