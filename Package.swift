// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "WebGame",
    
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WebGameLib",
            targets: ["WebGameLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", .upToNextMajor(from: "1.5.4")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .exact("6.1.0"))
    ],
    targets: [
        .target(
            name: "WebGameLib",
            dependencies: ["Swifter", "RxSwift", "RxCocoa"],
            path: "Sources"),
        .target(
            name: "WebGame",
            dependencies: ["WebGameLib"],
            path: "Executable"),
        .testTarget(
            name: "WebGameTests",
            dependencies: ["WebGameLib"],
            path: "Tests"),
    ]
)
