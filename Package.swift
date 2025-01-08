// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkingLayer",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetworkingLayer",
            targets: ["NetworkingLayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift", exact: Version(stringLiteral: "5.2.4")),
    ],
    targets: [
        .target(
            name: "NetworkingLayer",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift")
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("AdSupport"),
                .linkedFramework("Combine"),
                .linkedFramework("Security"),
                .linkedFramework("CommonCrypto"),
                .linkedFramework("CryptoKit"),
                .linkedFramework("CoreData"),
            ]
        ),
        .testTarget(
            name: "NetworkingLayerTests",
            dependencies: ["NetworkingLayer"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
