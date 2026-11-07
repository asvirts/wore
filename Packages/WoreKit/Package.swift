// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WoreKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "WoreCore", targets: ["WoreCore"]),
        .library(name: "WoreVision", targets: ["WoreVision"]),
        .library(name: "WoreStore", targets: ["WoreStore"]),
    ],
    targets: [
        .target(name: "WoreCore"),
        .target(name: "WoreVision", dependencies: ["WoreCore"]),
        .target(name: "WoreStore", dependencies: ["WoreCore"]),
        .testTarget(name: "WoreCoreTests", dependencies: ["WoreCore"]),
    ]
)
