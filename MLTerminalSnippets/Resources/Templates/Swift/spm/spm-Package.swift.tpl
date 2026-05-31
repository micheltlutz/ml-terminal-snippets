// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "{{PROJECT_NAME}}",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "{{PROJECT_NAME}}", targets: ["{{PROJECT_NAME}}"]),
    ],
    targets: [
        .target(name: "{{PROJECT_NAME}}"),
        .testTarget(name: "{{PROJECT_NAME}}Tests", dependencies: ["{{PROJECT_NAME}}"]),
    ]
)
