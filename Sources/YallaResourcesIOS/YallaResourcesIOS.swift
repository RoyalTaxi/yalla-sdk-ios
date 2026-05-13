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
        let normalizedName = name.hasSuffix(".svg") ? String(name.dropLast(4)) : name
        return bundle.url(
            forResource: normalizedName,
            withExtension: "svg",
            subdirectory: "Icons"
        ) ?? bundle.url(
            forResource: normalizedName,
            withExtension: "svg"
        )
    }
}
