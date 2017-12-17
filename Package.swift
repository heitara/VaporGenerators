// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporGenerators",
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", .upToNextMajor(from: "2.3.0"))
    ]
    // exclude: [
    //     "Templates"
    // ]
)
