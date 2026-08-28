// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasteCloneCore",
    products: [
        .library(name: "PasteCloneCore", targets: ["PasteCloneCore"])
    ],
    targets: [
        .target(name: "PasteCloneCore"),
        .testTarget(name: "PasteCloneCoreTests", dependencies: ["PasteCloneCore"])
    ]
)
