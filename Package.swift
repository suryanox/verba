// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Verba",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "Verba", targets: ["Verba"]),
    ],
    targets: [
        .executableTarget(
            name: "Verba",
            path: "Sources/Verba",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker",
                    "-sectcreate",
                    "-Xlinker",
                    "__TEXT",
                    "-Xlinker",
                    "__info_plist",
                    "-Xlinker",
                    "Config/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "VerbaTests",
            dependencies: ["Verba"],
            path: "Tests/VerbaTests"
        ),
    ]
)
