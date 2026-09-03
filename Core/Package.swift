// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DumplingBreathCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "DumplingBreathCore", targets: ["DumplingBreathCore"])
    ],
    targets: [
        .target(name: "DumplingBreathCore"),
        .testTarget(
            name: "DumplingBreathCoreTests",
            dependencies: ["DumplingBreathCore"]
        )
    ]
)
