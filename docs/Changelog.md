# Changelog

## 3.0.0-RC1
- Raised minimum deployment target from iOS 12.0 to iOS 13.0.
- Removed deprecated `registerDeviceTokenForPushNotifications` API from `WMTPush`.
- Removed deprecated `Cancellable` typealias. Use `WMTCancellable` directly.
- Added async/throws counterparts for all public callback-based methods in WMTOperations, WMTInbox, WMTPush, and WMTOIDC services.
- Added handling of `mtoken.statusChange` push notifications in `WMTPushParser` [(#227)](https://github.com/wultra/mtoken-sdk-ios/issues/227).
- Bumped dependency `PowerAuth2` to `2.0.x` (PowerAuth Mobile SDK 2.0). The `PowerAuthCore` module is no longer required and is no longer linked.
- Bumped dependency `WultraPowerAuthNetworking` to `2.0.x`.
- Migrated QR (offline) operation signing to the new asynchronous `PowerAuthSDK.offlineAuthenticationCode(...)` API. The behavior of `WMTOperations.authorize(qrOperation:...)` is unchanged from a caller's perspective.
- Reworked QR operation signature representation to support post-quantum-ready offline signatures:
    - Renamed `WMTQROperationSignature.SigningKey` to `WMTQROperationSignature.KeyType` and `signingKey` property to `keyType`.
    - Added new `macPersonalized` key type for KMAC-based MAC signatures (32-byte payload).
    - Replaced the Base64 `signature: String` property with raw `data: Data`.
    - Added `WMTQROperation.verifySignature(for:)` convenience method that verifies the signature using the proper PowerAuth key based on `keyType`.
    - Added `PowerAuthSDK.verifyDigitalSignature(of:)` extension for verifying a `WMTQROperation` directly from a `PowerAuthSDK` instance.
    - `WMTQROperationParser` can now accept an optional `PowerAuthSDK` instance via `init(powerAuth:)` to automatically verify the operation signature during parsing. Invalid signatures produce the new `signatureVerificationFailed` error.
- See [Migration from version `2.4.x` to `3.0.x`](Migration-3.0.md) for details.

## 2.5.0
- Improved proximity check time synchronization — the SDK now automatically adjusts timestamps during `authorize` [(#238)](https://github.com/wultra/mtoken-sdk-ios/issues/238).

## 2.4.0
- Added multiple PreApprovalScreens support [(#208)](https://github.com/wultra/mtoken-sdk-ios/issues/208).

## 2.3.0

- Added factory method `WMTProximityCheck.withSynchronizedTime` [(#201)](https://github.com/wultra/mtoken-sdk-ios/issues/201).
- Added support for Alert Attribute type [(#189)](https://github.com/wultra/mtoken-sdk-ios/issues/189).

## 2.2.1

- Fallback value (.pending) for `WMTUserOperation.status` if it is missing  [(#197)](https://github.com/wultra/mtoken-sdk-ios/issues/197).

## 2.2.0

- Added option for Firebase Cloud Messaging for Push Notifications and automatic APNS environment detection [(#174)](https://github.com/wultra/mtoken-sdk-ios/issues/174).

## 2.1.0

- Added `mobileTokenData` to authorize request for passing customer-specific data ([documentation](Using-Operations-Service.md#Passing-Additional-Mobile-Token-Data))
  - Available with PowerAuth server 1.10+
  - Can be used for fraud detection systems (FDS) or other custom business logic
- Dependency `networking-apple` is now required in version `1.5.1`

## 2.0.0

- Added status to `UserOperation` and removed redundant `OperationHistoryEntry` [(#171)](https://github.com/wultra/mtoken-sdk-ios/pull/171)
- SDK simplification and added `OIDC` activation feature [(#185)](https://github.com/wultra/mtoken-sdk-ios/pull/185)
    - [Migration guide](Migration-2.0.md)

## 1.12.0

- PowerAuth "server stack" `1.9+` is now required
- Dependency `powerauth-mobile-sdk` is now required in version `1.9.x`
- Dependency `networking-apple` is now required in version `1.5.x`

## 1.11.1

- Dependency `networking-apple` is now required in version `1.4.x`

## 1.11.0

- Added `resultTexts` to the `UserOperation` [(#160)](https://github.com/wultra/mtoken-sdk-ios/pull/160)
- Extended `PushParser` to support parsing of inbox notifications [(#158)](https://github.com/wultra/mtoken-sdk-ios/pull/158)
- Added `statusReason` to the `UserOperation` [(#156)](https://github.com/wultra/mtoken-sdk-ios/pull/156)
- Improved logging options [(#164)](https://github.com/wultra/mtoken-sdk-ios/pull/164)

## 1.10.0

- Removed `currentServerTime` property [(#148)](https://github.com/wultra/mtoken-sdk-android/pull/139)
- Added default and minimum pollingInterval [(#151)](https://github.com/wultra/mtoken-sdk-ios/pull/151)

## 1.9.0

- Added possibility for custom reject reason [(#143)](https://github.com/wultra/mtoken-sdk-ios/pull/143)
- Updated Amount and Conversion attributes to the new backend scheme [(#142)](https://github.com/wultra/mtoken-sdk-ios/pull/142)
- Fixed attribute deserialization [(#141)](https://github.com/wultra/mtoken-sdk-ios/pull/141)
- Added this changelog to the documentation

## 1.8.3

- Operation detail and non-personalized operation claim [(#132)](https://github.com/wultra/mtoken-sdk-ios/pull/132)

## 1.8.2

- Renamed proximity timestamps [(#135)](https://github.com/wultra/mtoken-sdk-ios/pull/135)

## 1.8.1

- Added `PACUtils` [(#133)](https://github.com/wultra/mtoken-sdk-ios/pull/133)

## 1.8.0

⚠️ This version of SDK requires PowerAuth Server version 1.5.0 and newer.

- Upgrade to PowerAuthSDK 1.8.0 [(#128)](https://github.com/wultra/mtoken-sdk-ios/pull/128)

## 1.7.3

- Renamed proximity timestamps [(#136)](https://github.com/wultra/mtoken-sdk-ios/pull/136)

## 1.7.2

- Added `PACUtils` [(#133)](https://github.com/wultra/mtoken-sdk-ios/pull/133)

## 1.7.0

- Fixed warnings when integrated with using SPM [(#119)](https://github.com/wultra/mtoken-sdk-ios/pull/119)
- Added support of QR Code & Deeplink - Proximity check [(#122)](https://github.com/wultra/mtoken-sdk-ios/pull/122)


## 1.6.0

- Added amount conversion attribute [(#109)](https://github.com/wultra/mtoken-sdk-ios/pull/109)
- Image attribute [(#110)](https://github.com/wultra/mtoken-sdk-ios/pull/110)
- Added server time property to operations [(#112)](https://github.com/wultra/mtoken-sdk-ios/pull/112)
- Update amount currency attributes with their formatted values [(#117)](https://github.com/wultra/mtoken-sdk-ios/pull/117)
- Moved UI object from the mtoken to SDK [(#118)](https://github.com/wultra/mtoken-sdk-ios/pull/118)


## 1.5.2

- Updated Inbox model classes

## 1.5.1

- Fixed podspec for inbox

## 1.5.0

- Added inbox feature
- Fixes and improvements


## 1.4.5

- Updated dependencies + running on Xcode 14 [(#98)](https://github.com/wultra/mtoken-sdk-ios/pull/98)

## 1.4.4

- Reject operation fix [(#97)](https://github.com/wultra/mtoken-sdk-ios/pull/97)

## 1.4.3

- Customizable URI ID used for offline signature [(#79)](https://github.com/wultra/mtoken-sdk-ios/pull/79)
- Possibility to use own WPNNetworkingService [(#80)](https://github.com/wultra/mtoken-sdk-ios/pull/80)
- Added possession factor as allowed signature variant [(#81)](https://github.com/wultra/mtoken-sdk-ios/pull/81)
- Upgrade to PowerAuth 1.7.x [(#85)](https://github.com/wultra/mtoken-sdk-ios/pull/85)
- Possibility of custom UserOperation object [(#94)](https://github.com/wultra/mtoken-sdk-ios/pull/94)
- Minor improvements and maintenance


## 1.4.2

- Updated dependencies

## 1.4.1

- Swift Package Manager support 🚀

## 1.4.0

- Networking code was moved to its own library. This allows sharing configuration and some error handling across Wultra libraries.

## 1.3.0

### Features

- Operation History API [(#64)](https://github.com/wultra/mtoken-sdk-ios/pull/64)
- Added "pause polling when on background" option [(#44)](https://github.com/wultra/mtoken-sdk-ios/pull/44)

### Fixes & Improvements

- PowerAuth Mobile SDK v 1.6.x is now required
- Fixed Operation Watcher [(#49)](https://github.com/wultra/mtoken-sdk-ios/pull/49)
- Improved documentation
- Updated dependencies


## 1.2.0

- Added option to start polling without waiting [(#45)](https://github.com/wultra/mtoken-sdk-ios/pull/45)
- Added "Operation Expiration Watcher" utility [(#42)](https://github.com/wultra/mtoken-sdk-ios/pull/42)

## 1.1.5

- An improved priority of error handling [(#35)](https://github.com/wultra/mtoken-sdk-ios/pull/35)

## 1.1.4

- Better error handling in networking [(#31)](https://github.com/wultra/mtoken-sdk-ios/pull/31)
- Executing public callbacks on the main thread [(#34)](https://github.com/wultra/mtoken-sdk-ios/pull/34)


## 1.1.3

- Added `WMTPushParser` class for parsing push notifications.

## 1.1.2

- Fixed validation error in `WMTQROperationParser`.

## 1.1.1

- Added the possibility to approve or reject operations received via different channels than this SDK.

## 1.1.0

- Naming changes to be consistent with the Android version
- Improved documentation.

## 1.0.1

- Documentation Improvements
- Improved offline operation parser

## 1.0.0

- Initial release of the iOS SDK.
