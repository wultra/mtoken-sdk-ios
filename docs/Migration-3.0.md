# Migration from 2.4.x to 3.0.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for iOS** version `2.4.x` to version `3.0.x`.

Version `3.0.x` integrates [PowerAuth Mobile SDK 2.0](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/Migration-from-1.9-to-2.0.md). PowerAuth 2.0 brings post-quantum cryptography readiness and removes the need to link `PowerAuthCore` separately. Most of the migration work happens in your application's PowerAuth integration; the public Mobile Token SDK API itself is largely source-compatible.



## Updated Dependencies

| Dependency | Old | New |
|---|---|---|
| `PowerAuth2` | `1.9.x` | `2.0.x` |
| `WultraPowerAuthNetworking` | `1.5.x` | `2.0.x` |
| `PowerAuthCore` | `1.9.x` | _no longer required, do not link_ |

### Swift Package Manager

Update your package requirements to `WultraMobileTokenSDK` `3.0.0`. Remove any explicit dependency on `PowerAuthCore` from your targets — the symbols previously exposed by `PowerAuthCore` are now part of `PowerAuth2`.

### CocoaPods

```rb
pod 'WultraMobileTokenSDK', '~> 3.0'
```

The `WultraMobileTokenSDK` podspec now requires `PowerAuth2 ~> 2.0` and `WultraPowerAuthNetworking ~> 2.0`. Remove `PowerAuthCore` from your `Podfile` if you previously listed it explicitly.

### Minimum deployment target

PowerAuth 2.0 raises the minimum deployment target to **iOS 13.0** (and macCatalyst 13.5). Your application must target at least iOS 13.


## Source-Code Migration

The Mobile Token SDK's public Swift API has not changed. You only need to adjust the parts of your application that interact directly with `PowerAuthSDK`. Refer to the upstream [PowerAuth Mobile SDK 2.0 migration guide](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/Migration-from-1.9-to-2.0.md) for the full list. 


## Behavioral Changes Inside the SDK

These are internal changes that don't require code modifications on your side, but are worth being aware of:

- The QR (offline) operation signing path inside `WMTOperations.authorize(qrOperation:...)` now uses PowerAuth's new asynchronous `offlineAuthenticationCode(...)` API. The `authorize(qrOperation:...)` method's signature, behavior, and threading guarantees are unchanged for callers.
