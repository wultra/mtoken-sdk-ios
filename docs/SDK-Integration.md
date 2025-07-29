# SDK Integration

## Requirements

- iOS 12.0+
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
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "YourLibrary",
            targets: ["YourLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/wultra/mtoken-sdk-ios.git", .from("1.12.0"))
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

## Guaranteed PowerAuth Compatibility

| WMT SDK               | PowerAuth SDK |
|-----------------------|---------------|
| `2.0.x`               | `1.9.x`       |
| `1.12.x`              | `1.9.x`       |
| `1.8.x` - `1.11.x`    | `1.8.x`       |
| `1.6.x` - `1.7.x`     | `1.7.x`       |
| `1.3.x` - `1.5.x`     | `1.6.x`       |
| `1.0.x` - `1.2.x`     | `1.5.x`       |

## Xcode Compatibility

We recommend using Xcode version 16.0 or newer.
