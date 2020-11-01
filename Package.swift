// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "UnixSockets",
  products: [
    .library(name: "UnixSockets", targets: ["UnixSockets"])
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/Spectre.git", from: "0.9.0")
  ],
  targets: [
    .target(name: "UnixSockets", dependencies: []),
    .testTarget(name: "UnixSocketsTests", dependencies: ["UnixSockets", "Spectre"])
  ]
)
