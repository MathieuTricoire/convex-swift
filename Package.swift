// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "824954d812f272973d6a0fd99213c3ea811949a584ffb97a96b8d4dc86aa5937"
let version = "0.0.2"
let url = "https://github.com/MathieuTricoire/convex-swift/releases/download/\(version)/ConvexFFI.xcframework.zip"

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
    ],
    targets: [
        .target(
            name: "Convex",
            dependencies: ["ConvexFFI"]
        ),
        .target(
            name: "ConvexFFI",
            dependencies: ["ConvexFFIFramework"]
        ),
        .binaryTarget(
            name: "ConvexFFIFramework",
            // For release artifacts, reference the ConvexFFI as an URL with checksum.
            url: url,
            checksum: checksum

            // For local testing, you can point at an (unzipped) XCFramework.
            // path: "../convex-rs-ffi/generated/swift/ConvexFFI.xcframework"
        ),

        // Test targets
        .testTarget(
            name: "ConvexTests",
            dependencies: ["Convex"]
        ),
    ]
)
