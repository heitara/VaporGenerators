// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporGenerators",
    products: [
        .library(name: "VaporGenerators", targets: ["VaporGenerators"]),
	],
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", .upToNextMajor(from: "2.3.0")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
    ],
	targets: [
	        .target(name: "VaporGenerators", dependencies: ["Console", "Vapor"], exclude: []),
	]
)
