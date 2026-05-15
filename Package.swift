// swift-tools-version: 5.9
// PixelDrop — A minimal macOS image viewer built on ImageViewerKit

import PackageDescription

let package = Package(
    name: "PixelDrop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Pull ImageViewerKit straight from GitHub so PixelDrop is self-contained.
        // (Local sibling path is no longer used — anyone cloning the repo gets it.)
        .package(url: "https://github.com/ogsezer/ImageViewerKit", from: "1.2.7")
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
