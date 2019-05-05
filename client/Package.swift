// swift-tools-version:5.0

import PackageDescription

var targets: [PackageDescription.Target] = [
	.target(name: "sslTest", dependencies: ["NIO", "NIOTransportServices"], path: "Sources"),
	.testTarget(name: "sslTestTests", dependencies: ["sslTest"]),
]

let package = Package(
    name: "sslTest",
	platforms: [
	        .macOS(.v10_14)
	    ],
	products: [
		.library(name: "sslTest", targets: ["sslTest"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.0.2"),
		.package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.0.1"),
	    ],
	targets: targets
)
 
