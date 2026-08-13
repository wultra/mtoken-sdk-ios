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
        .package(url: "https://github.com/wultra/powerauth-mobile-sdk.git", .upToNextMinor(from: "2.0.0"),
        .package(url: "https://github.com/wultra/networking-apple.git", .upToNextMinor(from: "2.0.0"))
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
