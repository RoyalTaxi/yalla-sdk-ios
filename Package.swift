// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "YallaSDKIOS",
    defaultLocalization: "uz-Latn",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "YallaSDKIOS",
            targets: ["YallaSDKIOS"]
        ),
        .library(
            name: "YallaResourcesIOS",
            targets: ["YallaResourcesIOS"]
        ),
        .library(
            name: "YallaDesignIOS",
            targets: ["YallaDesignIOS"]
        )
    ],
    targets: [
        .target(
            name: "YallaSDKIOS",
            dependencies: ["YallaResourcesIOS", "YallaDesignIOS"],
            path: "Sources/YallaSDKIOS"
        ),
        .target(
            name: "YallaDesignIOS",
            dependencies: ["YallaResourcesIOS"],
            path: "Sources/YallaDesignIOS"
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
            dependencies: ["YallaSDKIOS", "YallaResourcesIOS", "YallaDesignIOS"],
            path: "Tests/YallaSDKIOSTests"
        )
    ]
)
