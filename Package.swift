// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Ashton",
    platforms: [.iOS("13.4"), .macOS(.v10_15)],
    products: [.library(name: "Ashton", targets: ["Ashton"])],
    targets: [
        .target(
            name: "Ashton",
            dependencies: [],
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(
            name: "AshtonTests",
            dependencies: ["Ashton"],
            path: "Tests",
            exclude: ["TestFiles", "AshtonBenchmark", "Bridging.h", "AshtonBenchmarkTests.swift"]),
    ]
)
