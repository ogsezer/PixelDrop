// swift-tools-version: 5.9
// PixelDrop — A minimal macOS image viewer built on ImageViewerKit

import PackageDescription

let package = Package(
    name: "PixelDrop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // ImageViewerKit lives one directory up (sibling package)
        .package(path: "../ImageViewerKit")
    ],
    targets: [
        .executableTarget(
            name: "PixelDrop",
            dependencies: [
                .product(name: "ImageViewerKit", package: "ImageViewerKit")
            ],
            path: "Sources/PixelDrop",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
