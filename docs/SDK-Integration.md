# SDK Integration

## Requirements

- iOS 10.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) needs to be available in your project

## Cocoapods

To use **WMT** in you iOS app, add the following dependencies:

```rb
pod 'WultraMobileTokenSDK/Operations'
pod 'WultraMobileTokenSDK/Push'
```

<!-- begin box info -->
Note: If you want to use only operations, you can omit the Push dependency.
<!-- end -->

## Guaranteed PowerAuth Compatibility

| WMT SDK | PowerAuth SDK |  
|---|---|
| `1.0.x` - `1.2.x` | `1.x.x` |
| `1.3.x` | `1.6.x` |

## Xcode Compatibility

We recommend using Xcode version 12.5 or newer.
