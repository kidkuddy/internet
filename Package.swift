// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InternetTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "InternetTracker",
            path: "Sources"
        )
    ]
)
