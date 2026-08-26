// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HomeBrewInstaller",
    defaultLocalization: "ko",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HomeBrewInstaller",
            path: "Sources/HomeBrewInstaller",
            resources: [.process("Resources")]
        )
    ]
)
