// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-audio-content-analysis",
    defaultLocalization: "en",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(
            name: "SPFKAudioContentAnalysis",
            targets: ["SPFKAudioContentAnalysis", "SPFKAudioContentAnalysisC"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/CXXAudioContentAnalysis", branch: "development"),
    ],
    targets: [
        .target(
            name: "SPFKAudioContentAnalysis",
            dependencies: [
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),

                .targetItem(name: "SPFKAudioContentAnalysisC", condition: nil)
            ]
        ),
        .target(
            name: "SPFKAudioContentAnalysisC",
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
            name: "SPFKAudioContentAnalysisTests",
            dependencies: [
                .targetItem(name: "SPFKAudioContentAnalysis", condition: nil),
                .targetItem(name: "SPFKAudioContentAnalysisC", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
