// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MarkDownshift",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MarkDownshift",
            path: "Sources/MarkDownshift"
        )
    ],
    swiftLanguageModes: [.v5]
)
