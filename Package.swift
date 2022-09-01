// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ton",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "builder",
            targets: ["builder"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core", .upToNextMajor(from: "0.2.4")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "builder",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "SwiftToolsSupport-auto",
                    package: "swift-tools-support-core"
                ),
            ],
            path: "Sources/Builder",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
            ]
        ),
    ]
)
