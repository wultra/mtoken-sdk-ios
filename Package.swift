// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "WultraMobileTokenSDK",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "WultraMobileTokenSDK", targets: ["WultraMobileTokenSDK"])
    ],
    dependencies: [
        .package(name: "PowerAuth2", url: "https://github.com/wultra/powerauth-mobile-sdk-spm.git", .upToNextMinor(from: "1.6.2")),
        .package(name: "WultraPowerAuthNetworking", url: "https://github.com/wultra/networking-apple.git", .upToNextMinor(from: "1.1.0"))
    ],
    targets: [
        .target(
            name: "WultraMobileTokenSDK",
            dependencies: ["PowerAuth2", .product(name: "PowerAuthCore", package: "PowerAuth2"), "WultraPowerAuthNetworking"],
            path: "WultraMobileTokenSDK",
            exclude: ["ConfigFiles/Config.xcconfig", "ConfigFiles/Debug.xcconfig", "ConfigFiles/Release.xcconfig", "Info.plist", "Podfile"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
