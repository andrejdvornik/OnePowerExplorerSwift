// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnePowerExplorer",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(
            url: "https://github.com/pvieito/PythonKit.git",
            branch: "master"
        ),
    ],
    targets: [
        .executableTarget(
            name: "OnePowerExplorer",
            dependencies: [
                .product(name: "PythonKit", package: "PythonKit"),
            ],
            path: "OnePowerExplorer",
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-framework", "SwiftUI"])
            ]
        ),
    ]
)
