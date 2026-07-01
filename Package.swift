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
        )
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
