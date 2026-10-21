// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Unii",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "Unii",
            targets: ["Unii"]
        )
    ],
    targets: [
        .target(
            name: "Unii",
            dependencies: []
        ),
        .testTarget(
            name: "UniiTests",
            dependencies: ["Unii"]
        )
    ]
)
