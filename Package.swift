// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "WultraMobileTokenSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "WultraMobileTokenSDK", targets: ["WultraMobileTokenSDK"])
    ],
    dependencies: [
        // PowerAuth Mobile SDK 2.0+ provides full SPM support directly from its main repository.
        // The `PowerAuthCore` module is no longer exposed; all functionality is provided by `PowerAuth2`.
        .package(url: "https://github.com/wultra/powerauth-mobile-sdk.git", revision: "2.0.0-RC1"),
        .package(url: "https://github.com/wultra/networking-apple.git", revision: "2.0.0-RC1")
    ],
    targets: [
        .target(
            name: "WultraMobileTokenSDK",
            dependencies: [
                .product(name: "PowerAuth2", package: "powerauth-mobile-sdk"),
                .product(name: "WultraPowerAuthNetworking", package: "networking-apple")
            ],
            path: "WultraMobileTokenSDK",
            exclude: ["ConfigFiles/Config.xcconfig", "ConfigFiles/Debug.xcconfig", "ConfigFiles/Release.xcconfig", "Info.plist", "Podfile"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
