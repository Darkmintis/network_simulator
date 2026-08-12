// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network_simulator",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "network-simulator", targets: ["network_simulator"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "network_simulator",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            linkerSettings: [
                .linkedFramework("NetworkExtension"),
            ]
        ),
    ]
)
