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
        .package(url: "https://github.com/wultra/mtoken-sdk-ios.git", .from("1.7.0"))
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

Add the following dependencies to your Podfile:

```rb
pod 'WultraMobileTokenSDK/Operations'
pod 'WultraMobileTokenSDK/Push'
pod 'WultraMobileTokenSDK/Inbox'
```

<!-- begin box info -->
Note: If you want to use only operations, you can omit the Push dependency & Inbox dependency.
<!-- end -->

## Guaranteed PowerAuth Compatibility

| WMT SDK | PowerAuth SDK |  
|---|---|
| `1.0.x` - `1.2.x` | `1.x.x` |
| `1.3.x` | `1.6.x` |
| `1.4.x` | `1.6.x` |
| `1.5.x` | `1.6.x` |
| `1.6.x` | `1.7.x` |
| `1.7.x` | `1.7.x` |

## Xcode Compatibility

We recommend using Xcode version 15.0 or newer.
