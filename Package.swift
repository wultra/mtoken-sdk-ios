// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "WultraMobileTokenSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "WultraMobileTokenSDK", targets: ["WultraMobileTokenSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/wultra/powerauth-mobile-sdk-spm.git", .upToNextMinor(from: "1.7.8")),
        .package(url: "https://github.com/wultra/networking-apple.git", .upToNextMinor(from: "1.2.0"))
    ],
    targets: [
        .target(
            name: "WultraMobileTokenSDK",
            dependencies: [
                .product(name: "PowerAuth2", package: "powerauth-mobile-sdk-spm"),
                .product(name: "PowerAuthCore", package: "powerauth-mobile-sdk-spm"), 
                .product(name: "WultraPowerAuthNetworking", package: "networking-apple")
            ],
            path: "WultraMobileTokenSDK",
            exclude: ["ConfigFiles/Config.xcconfig", "ConfigFiles/Debug.xcconfig", "ConfigFiles/Release.xcconfig", "Info.plist", "Podfile"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
