import Foundation

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

    public static func iconURL(_ name: String) -> URL? {
        resourceURL(name, withExtension: "svg", subdirectory: "Icons")
    }

    public static func drawableURL(_ name: String) -> URL? {
        resourceURL(name, withExtension: "png", subdirectory: "Drawables")
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
        let suffix = ".\(fileExtension)"
        let normalizedName = name.hasSuffix(suffix) ? String(name.dropLast(suffix.count)) : name
        return bundle.url(
            forResource: normalizedName,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) ?? bundle.url(
            forResource: normalizedName,
            withExtension: fileExtension
        )
    }
}
