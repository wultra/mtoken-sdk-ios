# Wultra Mobile Token SDK for iOS

> NOTE: This SDK is under development. More information and documentation will follow.

## Purpose

Wultra Mobile Token SDK (WMT) is a high-level SDK written in `swift` for strong customer authentication operation confirmation.

This SDK is an addon to `PowerAuth2 Mobile SDK`.

**OPERATIONS**  
This SDK contains Operations subspec that handles operation retrieving, approving and rejecting.

**PUSH**  
This SDK contains Push subspec that handles registration to the Wultra Push server.


## Basic usage

### Integration

Integration is now supported only via CocoaPods.

Operation `podfile` config:  
`pod 'WultraMobileTokenSDK/Operations', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master'`

Push `podfile` config:   
`pod 'WultraMobileTokenSDK/Push', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master'`

### Code usage

To retrieve `WMTOperation` service from your PowerAuth activation, simply use:

```
let opsConfig = WMTConfig(
            baseUrl: URL(string: "http://mydomain.com/myservice/ops")!,
            sslValidation: .default,
            acceptLanguage: "en")
            
let opsService = pa2Instance.createWMTOperations(config: opsConfig)
```

To retrieve `WMTPush` service from your PowerAuth activation, simply use:

```
let pushConfig = WMTConfig(
            baseUrl: URL(string: "http://mydomain.com/myservice/push")!,
            sslValidation: .default,
            acceptLanguage: "en")
            
let pushService = pa2Instance.createWMTPush(config: pushConfig)
```