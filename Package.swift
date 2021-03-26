// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "WebGame",
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", .upToNextMajor(from: "1.5.4")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .exact("6.1.0"))
    ],
    targets: [
        .target(
            name: "WebGame",
            dependencies: ["Swifter", "RxSwift", "RxCocoa"],
            path: "Sources")
    ]
)
