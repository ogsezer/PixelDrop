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
            path: "Sources/PixelDrop"
            // StrictConcurrency intentionally omitted for the app target —
            // NSItemProvider (ObjC) is not Sendable, which trips Swift 6
            // sending-parameter checks. Strict concurrency lives in the
            // framework (ImageViewerKit), not the demo app.
        )
    ]
)
