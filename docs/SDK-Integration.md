# SDK Integration

## Requirements

- iOS 13.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) needs to be available in your project

## Swift Package Manager

Add `https://github.com/wultra/mtoken-sdk-ios` repository as a package in Xcode UI and add `WultraMobileTokenSDK` library as a dependency.

Alternatively, you can add the dependency manually. For example:

```swift
// swift-tools-version:5.7
import PackageDescription
let package = Package(
    name: "YourLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "YourLibrary",
            targets: ["YourLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/wultra/mtoken-sdk-ios.git", .from("3.0.0"))
    ],
    targets: [
        .target(
            name: "YourLibrary",
            dependencies: ["WultraMobileTokenSDK"]
        )
    ]
)
```

## Cocoapods

Add the following dependency to your Podfile:

```rb
pod 'WultraMobileTokenSDK'
```

## Xcode Compatibility

We recommend using Xcode version 16.0 or newer.
