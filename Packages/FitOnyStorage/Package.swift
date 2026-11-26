// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitOnyStorage",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "FitOnyStorage",
            targets: ["FitOnyStorage"]
        )
    ],
    dependencies: [
        .package(path: "../FitOnyCore")
    ],
    targets: [
        .target(
            name: "FitOnyStorage",
            dependencies: [
                .product(name: "FitOnyCore", package: "FitOnyCore")
            ]
        ),
        .testTarget(
            name: "FitOnyStorageTests",
            dependencies: [
                "FitOnyStorage",
                .product(name: "FitOnyCore", package: "FitOnyCore")
            ]
        )
    ]
)
