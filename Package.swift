// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "WebGame",
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", .upToNextMajor(from: "1.5.1"))
    ],
    targets: [
        .target(
            name: "WebGame",
            dependencies: ["Swifter"],
            path: "Sources")
    ]
)
