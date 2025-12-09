// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChessKit",
    products: [
        .library(
            name: "ChessKit",
            targets: ["ChessKit"]
        ),
        .library(
            name: "ChessKitUI",
            targets: ["ChessKitUI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ChessKit",
            dependencies: []
        ),
        .target(
            name: "ChessKitUI",
            dependencies: ["ChessKit"]
        ),
        .testTarget(
            name: "ChessKitTests",
            dependencies: ["ChessKit"]
        ),
    ]
)
