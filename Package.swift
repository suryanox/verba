// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Verba",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Verba", targets: ["Verba"])
    ],
    targets: [
        .executableTarget(
            name: "Verba",
            path: "Sources/Verba"
        ),
        .testTarget(
            name: "VerbaTests",
            dependencies: ["Verba"],
            path: "Tests/VerbaTests"
        )
    ]
)
