// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Financio",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Financio", targets: ["Financio"])
    ],
    targets: [
        .executableTarget(
            name: "Financio",
            path: "Sources/Financio"
        )
    ]
)
