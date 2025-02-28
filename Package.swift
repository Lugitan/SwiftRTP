// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRTP",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftRTP",
            targets: ["SwiftRTP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/Lugitan/BinaryKit.git",
            from: "4.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftRTP",
            dependencies: ["BinaryKit"]),
        .testTarget(
            name: "SwiftRTPTests",
            dependencies: ["SwiftRTP", "BinaryKit"]),
        .testTarget(
            name: "SwiftRTPPerformanceTests",
            dependencies: ["SwiftRTP", "BinaryKit"]),
    ]
)
