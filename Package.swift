// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "VoicePolishInput",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "VoicePolishInput", targets: ["VoicePolishInput"]),
    ],
    targets: [
        .executableTarget(
            name: "VoicePolishInput"
        ),
    ]
)
