// swift-tools-version:5.9
// Standalone test harness for PrivacyLens's pure logic (Models + Helpers).
// The Xcode project builds the app; `swift test` runs the unit tests.
import PackageDescription

let package = Package(
    name: "PrivacyLens",
    targets: [
        .target(
            name: "PrivacyLens",
            path: "PrivacyLens",
            exclude: ["PrivacyLensApp.swift", "Views", "ViewModels", "Assets.xcassets"]
        ),
        .testTarget(
            name: "PrivacyLensTests",
            dependencies: ["PrivacyLens"],
            path: "Tests/PrivacyLensTests"
        ),
    ]
)