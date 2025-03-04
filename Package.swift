// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "WebGame",

    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WebGameLib",
            targets: ["WebGameLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", branch: "develop"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: "6.5.0"),
        .package(url: "https://github.com/tomieq/WebRequest.swift.git", exact: "1.0.2"  )
    ],
    targets: [
        .target(
            name: "WebGameLib",
            dependencies: [
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "WebRequest", package: "WebRequest.swift")
            ],
            path: "Sources"),
        .target(
            name: "WebGame",
            dependencies: ["WebGameLib",
                           .product(name: "Swifter", package: "Swifter"),
                           .product(name: "RxSwift", package: "RxSwift"),
                           .product(name: "RxCocoa", package: "RxSwift"),
                           .product(name: "WebRequest", package: "WebRequest.swift")
            ],
            path: "Executable"),
        .testTarget(
            name: "WebGameTests",
            dependencies: ["WebGameLib",
                           .product(name: "Swifter", package: "Swifter"),
                           .product(name: "RxSwift", package: "RxSwift"),
                           .product(name: "RxCocoa", package: "RxSwift")
            ],
            path: "Tests")
    ]
)
