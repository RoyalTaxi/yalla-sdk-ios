// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "YallaSDKIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "YallaSDKIOS",
            targets: ["YallaSDKIOS"]
        )
    ],
    targets: [
        .target(
            name: "YallaSDKIOS",
            path: "Sources/YallaSDKIOS"
        ),
        .testTarget(
            name: "YallaSDKIOSTests",
            dependencies: ["YallaSDKIOS"],
            path: "Tests/YallaSDKIOSTests"
        )
    ]
)
