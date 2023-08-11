// swift-tools-version:5.1
import PackageDescription

#if compiler(>=5.9)
let platforms: [Package.Platform] = [.iOS("13.4"), .macOS(.v10_15), .visionOS(.v1)]
#else
let platforms: [Package.Platform] = [.iOS("13.4"), .macOS(.v10_15)]
#endif

let package = Package(
    name: "Ashton",
    platforms: platforms,
    products: [.library(name: "Ashton", targets: ["Ashton"])],
    targets: [
        .target(
            name: "Ashton",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "AshtonTests",
            dependencies: ["Ashton"],
            path: "Tests",
            exclude: ["TestFiles", "AshtonBenchmark", "Bridging.h", "AshtonBenchmarkTests.swift"]),
    ]
)
