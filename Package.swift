// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Convex",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v12),
        .watchOS(.v7),
    ],
    products: [
        .library(name: "Convex", targets: ["Convex"]),
        .library(name: "ConvexHTTP", targets: ["ConvexHTTP"]),
        .library(name: "ConvexWebSocket", targets: ["ConvexWebSocket"]),
        .library(name: "ConvexSwiftUI", targets: ["ConvexSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "Convex"
        ),
        .target(
            name: "ConvexHTTP",
            dependencies: [
                "Convex",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "ConvexWebSocket",
            dependencies: [
                "Convex",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "ConvexSwiftUI",
            dependencies: [
                "ConvexWebSocket",
            ]
        ),
        .target(name: "TestHelpers", path: "Tests/Helpers"),

        // Test targets

        .testTarget(
            name: "ConvexTests",
            dependencies: ["Convex", "TestHelpers"]
        ),
        // .testTarget(
        //     name: "ConvexHTTPTests",
        //     dependencies: ["ConvexHTTP"]
        // ),
        .testTarget(
            name: "ConvexWebSocketTests",
            dependencies: ["ConvexWebSocket", "TestHelpers"]
        ),
    ]
)
