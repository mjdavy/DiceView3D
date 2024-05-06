// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiceView3D",
    platforms: [
        .iOS(.v17) // This line restricts the package to iOS 17 and later
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DiceView3D",
            targets: ["DiceView3D"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DiceView3D"),
        .testTarget(
            name: "DiceView3DTests",
            dependencies: ["DiceView3D"]),
    ]
)
