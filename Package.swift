// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Convex",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v12), .watchOS(.v7)],
    products: [
        .library(
            name: "Convex",
            targets: ["Convex"]
        ),
    ],
    targets: [
        .target(
            name: "Convex"),
        .testTarget(
            name: "ConvexTests",
            dependencies: ["Convex"]
        ),
    ]
)

for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(
        .unsafeFlags([
            "-enable-bare-slash-regex",
        ])
    )
}
