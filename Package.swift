// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppFactoryKit",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        // Drop-in core: onboarding + hard paywall + subscription state + analytics funnel.
        // No third-party dependencies — compiles and previews standalone.
        .library(name: "AppFactoryKit", targets: ["AppFactoryKit"]),
        // Opt-in adapter that backs the core with RevenueCat. Pulls the Purchases SDK.
        .library(name: "AppFactoryKitRevenueCat", targets: ["AppFactoryKitRevenueCat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "AppFactoryKit"),
        .target(
            name: "AppFactoryKitRevenueCat",
            dependencies: [
                "AppFactoryKit",
                .product(name: "RevenueCat", package: "purchases-ios"),
            ]
        ),
        .testTarget(name: "AppFactoryKitTests", dependencies: ["AppFactoryKit"]),
    ]
)
