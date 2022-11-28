// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CLPlayer",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "CLPlayer", targets: ["CLPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.6.0")),
    ],
    targets: [
        .target(name: "CLPlayer", dependencies: ["SnapKit"]),
    ]
)
