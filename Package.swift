// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonitorApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MonitorApp", targets: ["MonitorApp"])
    ],
    targets: [
        .executableTarget(
            name: "MonitorApp",
            path: "Sources/MonitorApp"
        )
    ]
)
