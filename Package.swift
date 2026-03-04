// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-musical-analysis",
    defaultLocalization: "en",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(
            name: "SPFKMusicalAnalysis",
            targets: ["SPFKMusicalAnalysis"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "SPFKMusicalAnalysis",
            dependencies: [
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
            ]
        ),
        .testTarget(
            name: "SPFKMusicalAnalysisTests",
            dependencies: [
                .targetItem(name: "SPFKMusicalAnalysis", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
