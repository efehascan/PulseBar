// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PulseBar",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "PulseBar", targets: ["PulseBar"])],
    targets: [
        .target(name: "PulseBarCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .executableTarget(name: "PulseBar", dependencies: ["PulseBarCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "PulseBarCoreTests", dependencies: ["PulseBarCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
