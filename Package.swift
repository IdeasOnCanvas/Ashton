// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Ashton",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9)
    ],
    products: [
        .library(name: "Ashton", targets: ["Ashton"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Ashton", dependencies: [])
    ]
)

