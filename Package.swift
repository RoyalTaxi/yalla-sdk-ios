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
            name: "YallaSDKIOS",
            targets: ["YallaSDKIOS"]
        ),
        .library(
            name: "YallaResourcesIOS",
            targets: ["YallaResourcesIOS"]
        )
    ],
    targets: [
        .target(
            name: "YallaSDKIOS",
            dependencies: ["YallaResourcesIOS"],
            path: "Sources/YallaSDKIOS"
        ),
        .target(
            name: "YallaResourcesIOS",
            path: "Sources/YallaResourcesIOS",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "YallaSDKIOSTests",
            dependencies: ["YallaSDKIOS", "YallaResourcesIOS"],
            path: "Tests/YallaSDKIOSTests"
        )
    ]
)
