// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CLPlayer",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "CLPlayer",
            targets: ["CLPlayer"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CLPlayer",
            dependencies: [])
    ]
)
