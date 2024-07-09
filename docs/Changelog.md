# Changelog

## 1.11.1 (July 2024)

- Dependency `networking-apple` is now required in version `1.4.x`

## 1.11.0 (July 2024)

- Added `resultTexts` to the `UserOperation` [(#160)](https://github.com/wultra/mtoken-sdk-ios/pull/160)
- Extended `PushParser` to support parsing of inbox notifications [(#158)](https://github.com/wultra/mtoken-sdk-ios/pull/158)
- Added `statusReason` to the `UserOperation` [(#156)](https://github.com/wultra/mtoken-sdk-ios/pull/156)
- Improved logging options [(#164)](https://github.com/wultra/mtoken-sdk-ios/pull/164)

## 1.10.0 (Apr 18, 2024)

- Removed `currentServerTime` property [(#148)](https://github.com/wultra/mtoken-sdk-android/pull/139)
- Added default and minimum pollingInterval [(#151)](https://github.com/wultra/mtoken-sdk-ios/pull/151)

## 1.9.0 (Jan 24, 2024)

- Added possibility for custom reject reason [(#143)](https://github.com/wultra/mtoken-sdk-ios/pull/143)
- Updated Amount and Conversion attributes to the new backend scheme [(#142)](https://github.com/wultra/mtoken-sdk-ios/pull/142)
- Fixed attribute deserialization [(#141)](https://github.com/wultra/mtoken-sdk-ios/pull/141)
- Added this changelog to the documentation

## 1.8.3 (Jan 9, 2024)

- Operation detail and non-personalized operation claim [(#132)](https://github.com/wultra/mtoken-sdk-ios/pull/132)

## 1.8.2 (Dec 15, 2023)

- Renamed proximity timestamps [(#135)](https://github.com/wultra/mtoken-sdk-ios/pull/135)

## 1.8.1 (Nov 30, 2023)

- Added `PACUtils` [(#133)](https://github.com/wultra/mtoken-sdk-ios/pull/133)

## 1.8.0 (Nov 24, 2023)

⚠️ This version of SDK requires PowerAuth Server version 1.5.0 and newer.

- Upgrade to PowerAuthSDK 1.8.0 [(#128)](https://github.com/wultra/mtoken-sdk-ios/pull/128)

## 1.7.3 (Dec 15, 2023)

- Renamed proximity timestamps [(#136)](https://github.com/wultra/mtoken-sdk-ios/pull/136)

## 1.7.2 (Nov 30, 2023)

- Added `PACUtils` [(#133)](https://github.com/wultra/mtoken-sdk-ios/pull/133)

## 1.7.0 (Nov 13, 2023)

- Fixed warnings when integrated with using SPM [(#119)](https://github.com/wultra/mtoken-sdk-ios/pull/119)
- Added support of QR Code & Deeplink - Proximity check [(#122)](https://github.com/wultra/mtoken-sdk-ios/pull/122)


## 1.6.0 (Jun 23, 2023)

- Added amount conversion attribute [(#109)](https://github.com/wultra/mtoken-sdk-ios/pull/109)
- Image attribute [(#110)](https://github.com/wultra/mtoken-sdk-ios/pull/110)
- Added server time property to operations [(#112)](https://github.com/wultra/mtoken-sdk-ios/pull/112)
- Update amount currency attributes with their formatted values [(#117)](https://github.com/wultra/mtoken-sdk-ios/pull/117)
- Moved UI object from the mtoken to SDK [(#118)](https://github.com/wultra/mtoken-sdk-ios/pull/118)


## 1.5.2  (Jan 16, 2023)

- Updated Inbox model classes

## 1.5.1 (Jan 12, 2023)

- Fixed podspec for inbox

## 1.5.0 (Jan 12, 2023)

- Added inbox feature
- Fixes and improvements


## 1.4.5 (Oct 5, 2022)

- Updated dependencies + running on Xcode 14 [(#98)](https://github.com/wultra/mtoken-sdk-ios/pull/98)

## 1.4.4 (Aug 30, 2022)

- Reject operation fix [(#97)](https://github.com/wultra/mtoken-sdk-ios/pull/97)

## 1.4.3 (Aug 25, 2022)

- Customizable URI ID used for offline signature [(#79)](https://github.com/wultra/mtoken-sdk-ios/pull/79)
- Possibility to use own WPNNetworkingService [(#80)](https://github.com/wultra/mtoken-sdk-ios/pull/80)
- Added possession factor as allowed signature variant [(#81)](https://github.com/wultra/mtoken-sdk-ios/pull/81)
- Upgrade to PowerAuth 1.7.x [(#85)](https://github.com/wultra/mtoken-sdk-ios/pull/85)
- Possibility of custom UserOperation object [(#94)](https://github.com/wultra/mtoken-sdk-ios/pull/94)
- Minor improvements and maintenance


## 1.4.2 (Jul 27, 2022)

- Updated dependencies

## 1.4.1 (Feb 3, 2022)

- Swift Package Manager support 🚀

## 1.4.0 (Sep 24, 2021)

- Networking code was moved to its own library. This allows sharing configuration and some error handling across Wultra libraries.

## 1.3.0 (Aug 18, 2021)

### Features

- Operation History API [(#64)](https://github.com/wultra/mtoken-sdk-ios/pull/64)
- Added "pause polling when on background" option [(#44)](https://github.com/wultra/mtoken-sdk-ios/pull/44)

### Fixes & Improvements

- PowerAuth Mobile SDK v 1.6.x is now required
- Fixed Operation Watcher [(#49)](https://github.com/wultra/mtoken-sdk-ios/pull/49)
- Improved documentation
- Updated dependencies


## 1.2.0 (Mar 5, 2021)

- Added option to start polling without waiting [(#45)](https://github.com/wultra/mtoken-sdk-ios/pull/45)
- Added "Operation Expiration Watcher" utility [(#42)](https://github.com/wultra/mtoken-sdk-ios/pull/42)

## 1.1.5 (Oct 30, 2020)

- An improved priority of error handling [(#35)](https://github.com/wultra/mtoken-sdk-ios/pull/35)

## 1.1.4 (Oct 26, 2020)

- Better error handling in networking [(#31)](https://github.com/wultra/mtoken-sdk-ios/pull/31)
- Executing public callbacks on the main thread [(#34)](https://github.com/wultra/mtoken-sdk-ios/pull/34)


## 1.1.3 (Aug 24, 2020)

- Added `WMTPushParser` class for parsing push notifications.

## 1.1.2 (Jun 1, 2020)

- Fixed validation error in `WMTQROperationParser`.

## 1.1.1 (Jun 1, 2020)

- Added the possibility to approve or reject operations received via different channels than this SDK.

## 1.1.0 (May 19, 2020)

- Naming changes to be consistent with the Android version
- Improved documentation.

## 1.0.1 (May 6, 2020)

- Documentation Improvements
- Improved offline operation parser

