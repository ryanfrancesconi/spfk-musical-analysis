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
            targets: ["SPFKMusicalAnalysis", "SPFKMusicalAnalysisC"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/CXXAudioContentAnalysis", from: "0.3.1"),
    ],
    targets: [
        .target(
            name: "SPFKMusicalAnalysis",
            dependencies: [
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),

                .targetItem(name: "SPFKMusicalAnalysisC", condition: nil)
            ]
        ),
        .target(
            name: "SPFKMusicalAnalysisC",
            dependencies: [
                .product(name: "AudioContentAnalysis", package: "CXXAudioContentAnalysis")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include_private")
            ],
            cxxSettings: [
                .headerSearchPath("include_private")
            ]
        ),
        .testTarget(
            name: "SPFKMusicalAnalysisTests",
            dependencies: [
                .targetItem(name: "SPFKMusicalAnalysis", condition: nil),
                .targetItem(name: "SPFKMusicalAnalysisC", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
