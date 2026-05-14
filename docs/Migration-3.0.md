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

Most of the Mobile Token SDK's public Swift API is unchanged. You need to adjust the parts of your application that interact directly with `PowerAuthSDK` (refer to the upstream [PowerAuth Mobile SDK 2.0 migration guide](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/Migration-from-1.9-to-2.0.md) for the full list), and a few QR-operation symbols described below.

### QR Operation Signature

The `WMTQROperationSignature` type has been reworked to support post-quantum-ready offline signatures (KMAC-based MAC signatures) alongside the existing ECDSA-based master and personalized signatures.

| Old (2.4.x) | New (3.0.x) |
|---|---|
| `WMTQROperationSignature.SigningKey` | `WMTQROperationSignature.KeyType` |
| `signature.signingKey` | `signature.keyType` |
| `signature.signature: String` (Base64) | `signature.data: Data` (raw) |
| _n/a_ | `.macPersonalized` case (32-byte MAC) |
| _n/a_ | `WMTQROperation.verifySignature(for: PowerAuthSDK)` |
| _n/a_ | `PowerAuthSDK.verifyDigitalSignature(of: WMTQROperation)` |
| _n/a_ | `WMTQROperationParser(powerAuth: PowerAuthSDK?)` |
| _n/a_ | `WMTQROperationParserError.signatureVerificationFailed` |

The recommended way to verify a parsed QR operation is to pass a `PowerAuthSDK` instance to the parser during initialization. The parser then verifies the signature automatically and returns `signatureVerificationFailed` if it is invalid:

```swift
// After (3.0.x) — recommended: automatic verification during parsing
let parser = WMTQROperationParser(powerAuth: powerAuth)
let op = try parser.parse(string: code).get()
// signature is already verified
```

You can also verify manually using either the operation or the `PowerAuthSDK` extension:

```swift
// Before (2.4.x)
let key: PowerAuthSignatureKeyId = op.signature.signingKey == .master ? .master_EC : .server_EC
try powerAuth.verifyDigitalSignature(signature: op.signature.signature, forData: op.signedData, withKey: key)

// After (3.0.x) — manual verification
try op.verifySignature(for: powerAuth)
// or equivalently:
try powerAuth.verifyDigitalSignature(of: op)
```

If you need to verify the signature manually, use `signature.data` together with `signature.keyType.powerAuthKey`, which maps each `KeyType` to the appropriate `PowerAuthSignatureKeyId` (`.master_EC`, `.device_EC`, or `.macPersonalized`).

### Removed `Cancellable` Typealias

The deprecated `Cancellable` typealias has been removed. Use `WMTCancellable` directly.

```swift
// Before
let task: Cancellable = operations.getOperations { ... }
// After
let task: WMTCancellable = operations.getOperations { ... }
```


## Behavioral Changes Inside the SDK

These are internal changes that don't require code modifications on your side, but are worth being aware of:

- The QR (offline) operation signing path inside `WMTOperations.authorize(qrOperation:...)` now uses PowerAuth's new asynchronous `offlineAuthenticationCode(...)` API. The `authorize(qrOperation:...)` method's signature, behavior, and threading guarantees are unchanged for callers.
