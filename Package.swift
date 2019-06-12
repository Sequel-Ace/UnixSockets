// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "fd",
  products: [
    .library(name: "fd", targets: ["fd"])
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/Spectre.git", from: "0.9.0")
  ],
  targets: [
    .target(name: "fd", dependencies: [], path: "Sources"),
    .testTarget(name: "fdTests", dependencies: ["fd", "Spectre"], path: "Tests/fdTests")
  ]
)
