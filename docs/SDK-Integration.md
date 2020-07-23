# SDK integration

## Requirements

- iOS 10.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) needs to be available in your project 

## Cocoapods

To use **WMT** in you iOS app, add the following dependencies:

```rb
pod 'WultraMobileTokenSDK/Operations'
pod 'WultraMobileTokenSDK/Push'
```

_Note: If you want to use only operations, you can omit the Push dependency._

## PowerAuth compatibility
| WMT SDK | PowerAuth SDK |  
|---|---|
| `1.x.x` | `1.x.x` |