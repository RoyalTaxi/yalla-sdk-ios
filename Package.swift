// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "YallaSDKIOS",
    defaultLocalization: "uz-Latn",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Resources",
            targets: ["Resources"]
        ),
        .library(
            name: "Design",
            targets: ["Design"]
        ),
        .library(
            name: "Bridges",
            targets: ["Bridges"]
        ),
        .library(
            name: "Maps",
            targets: ["Maps"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "10.0.0"),
        .package(url: "https://github.com/maplibre/maplibre-gl-native-distribution.git", from: "6.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "YallaComponents",
            path: "../yalla-sdk/components/build/XCFrameworks/debug/YallaComponents.xcframework"
        ),
        .target(
            name: "Resources",
            path: "Sources/Resources",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "Design",
            dependencies: ["Resources"],
            path: "Sources/Design"
        ),
        .target(
            name: "Bridges",
            dependencies: [
                "Design",
                "Resources",
                "YallaComponents"
            ],
            path: "Sources/Bridges"
        ),
        .target(
            name: "Maps",
            dependencies: [
                "YallaComponents",
                "Resources",
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
                .product(name: "MapLibre", package: "maplibre-gl-native-distribution")
            ],
            path: "Sources/Maps"
        ),
        .testTarget(
            name: "MapsTests",
            dependencies: [
                "Maps",
                "YallaComponents"
            ],
            path: "Tests/MapsTests"
        ),
        .testTarget(
            name: "BridgesTests",
            dependencies: [
                "Bridges",
                "YallaComponents"
            ],
            path: "Tests/BridgesTests"
        )
    ]
)
