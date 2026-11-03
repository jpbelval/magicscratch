// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Illusion",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Illusion", targets: ["Illusion"])],
    targets: [
        .target(
            name: "Illusion",
            path: "Illusion",
            exclude: ["Info.plist", "Assets.xcassets", "PrivacyInfo.xcprivacy"],
            sources: ["IllusionApp.swift", "Studio.swift", "MagicCanvas.swift", "StudioView.swift"]
        )
    ],
    swiftLanguageModes: [.v5]
)
