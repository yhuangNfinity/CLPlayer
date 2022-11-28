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
    dependencies: [
        .package(
      name: "SnapKit",
      url: "https://github.com/SnapKit/SnapKit",
      "5.0.0" ..< "6.0.0"),
    ],
    targets: [
        .target(
            name: "CLPlayer",
            dependencies: [.product(name: "SnapKit", package: "SnapKit")])
    ]
)
