// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitOnyCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "FitOnyCore",
            targets: ["FitOnyCore"]
        ),
        .executable(
            name: "FitOnyCoreVerify",
            targets: ["FitOnyCoreVerify"]
        )
    ],
    targets: [
        .target(
            name: "FitOnyCore"
        ),
        .executableTarget(
            name: "FitOnyCoreVerify",
            dependencies: ["FitOnyCore"]
        ),
        .testTarget(
            name: "FitOnyCoreTests",
            dependencies: ["FitOnyCore"]
        )
    ]
)
