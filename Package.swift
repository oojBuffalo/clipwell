// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clipwell",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Clipwell", targets: ["Clipwell"])
    ],
    targets: [
        .executableTarget(name: "Clipwell"),
        .testTarget(name: "ClipwellTests", dependencies: ["Clipwell"])
    ]
)
