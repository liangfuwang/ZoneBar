// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TimeBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "TimeBar", path: "Sources/TimeBar")
    ]
)
