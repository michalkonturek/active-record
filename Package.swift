// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "active-record",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "active-record",
            targets: ["active-record"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "active-record"
        ),
        .executableTarget(
          name: "demo",
          dependencies: ["active-record"],
          path: "Demo"
        ),
        .testTarget(
            name: "active-record-tests",
            dependencies: ["active-record"]
        ),
    ]
)
