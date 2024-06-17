// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "zenea-swift-cli",
    platforms: [
        .macOS("13.3")
    ],
    products: [
        .executable(name: "zenea-cli", targets: ["ZeneaCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.64.0"),
        .package(url: "https://github.com/zenea-project/zenea-swift.git", from: "3.0.2"),
        .package(url: "https://github.com/zenea-project/zenea-swift-files.git", from: "1.0.0"),
        .package(url: "https://github.com/zenea-project/zenea-swift-http.git", from: "1.0.0"),
        .package(url: "https://github.com/zenea-project/valya-swift.git", from: "1.0.3"),
    ],
    targets: [
        .executableTarget(
            name: "ZeneaCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                .product(name: "zenea-swift", package: "zenea-swift"),
                .product(name: "zenea-files", package: "zenea-swift-files"),
                .product(name: "zenea-swift-http", package: "zenea-swift-http"),
                .product(name: "valya-swift", package: "valya-swift"),
            ],
            path: "./Sources/zenea-cli"
        )
    ]
)
