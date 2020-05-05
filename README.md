# Wultra Mobile Token SDK for iOS

<!-- begin remove -->
`Wultra Mobile Token SDK` is a high-level SDK for operation approval.
<!-- end -->
<!-- begin TOC -->
- [Introduction](#introduction)
- [Installation](#installation)
    - [Requirements](#requirements)
    - [Cocoapods](#cocoapods)
- [Usage](#usage)
    - [Operations](#operations)
    - [Push](#push)
    - [Error handling](#error-handling)
- [License](#license)
- [Contact](#contact)
    - [Security Disclosure](#security-disclosure)
<!-- end -->

## Introduction
 
With `Wultra Mobile Token (WMT) SDK`, you will make access to your digital channels easier for your customers with a highly secure and user-friendly means of authentication and authorizing operations.

WMT is built on top of [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk#docucheck-keep-link) and is communication with `Mobile Token REST API` and `Mobile Push Registration API` endpoints described in [PowerAuth Webflow documentation](https://developers.wultra.com/docs/2019.11/powerauth-webflow/) 

To understand `WMT SDK` application-level purpose, you can visit our own [Mobile Token application](https://www.wultra.com/mobile-token#docucheck-keep-link) that is integrating this SDK.

`Wultra Mobile Token SDK` library does precisely this:
- Registering powerauth activation to receive push notifications
- Retrieving list of operations that are pending for approval
- Approving and rejecting operations with PowerAuth authentications

> We also provide an [Android version of this library](https://github.com/wultra/mtoken-sdk-android#docucheck-keep-link)

## Installation

### Requirements

- iOS 10+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk#docucheck-keep-link) needs to be available in your project 

### Cocoapods

To use **WMT** in you iOS app add following dependencies:

> Note: If you want to use only operations, you can omit the Push dependency.

```rb
pod 'WultraMobileTokenSDK/Operations', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master'
pod 'WultraMobileTokenSDK/Push', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master
```

## Usage

To use this library, you need to have `PowerAuthSDK` object available and initialized with valid activation. 
If not, all endpoints will return an error.

### Operations

This part of the SDK communicates with [Mobile Token API endpoints](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Token-API.md).

#### Configuration

To create an instance for operations service, use following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
            baseUrl: URL(string: "https://myservice.com/mtoken/operations/api/")!,
            sslValidation: .default
            )
let opsService = powerAuth.createWMTOperations(config: config)
```

#### WMTOperations API

- `delegate` - Delegate object that receives info about operation loading
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request. The server will return properly localized content based on this value.
- `lastFetchResult()` - Cached last operations result
- `isLoadingOperations` - If the service is loading operations
- `refreshOperations` - Async "fire and forget" request to refresh operations
- `getOperations(completion: @escaping GetOperationsCompletion)` - Retrieves operations from the server
    - `completion` - Called when operation finishes
- `isPollingOperations` - If the operations are periodically polling from the server
- `startPollingOperations(interval: TimeInterval)` - Starts periodic operation polling
    - `interval` - How often should operations be refreshed 
- `stopPollingOperations()` - Stops periodic operation polling
- `authorize(operation: WMTUserOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?)->Void)` - Authorize operation on the backend
    - `operation` - Operation to approve, retrieved from `getOperations` call
    - `authentication` - PowerAuth authentication object for operation signing
    - `completion` - Called when authorization request finishes
- `reject(operation: WMTUserOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?)->Void)` - Reject operation on the backend
    - `operation` - Operation to reject, retrieved from `getOperations` call
    - `reason` - Rejection reason
    - `completion` - Called when rejection request finishes
- `authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation
    - `operation` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method
    - `authentication` - PowerAuth authentication object for operation signing
    - `completion` - Called when authentication finishes

For more details on the API, visit [`WMTOperations` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/WMTOperations.swift).

#### Offline Operation Parsing

When implementing offline (QR) operation scanner, you'll need to process the scanned string to `WMTQROperation`. For this, you can use `WMTQROperationParser.parse` static function.

```swift
import WultraMobileTokenSDK

guard let parsedQROp = WMTQROperationParser.parse(string: decodedQrValue) else {
    return
}
// use parsed QR operation...
```

### Push

This part of the SDK communicates with [Mobile Push Registration API](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Push-Registration-API.md).

#### Configuration

To create an instance for push service, use following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
            baseUrl: URL(string: "https://myservice.com/mtoken/push/api/")!,
            sslValidation: .default
            )
let pushService = powerAuth.createWMTPush(config: config)
```

#### WMTPush API

- `pushNotificationsRegisteredOnServer` - If there was already made an successful request
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void)` - Registers push token on the backend
    - `token` - token data retrieved from APNS
    - `completionHandler` - Called when request finishes

For more details on the API, visit [`WMTPush` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Push/WMTPush.swift).

### Error handling

Every error that this library can produce is of type `WMTError`. This error contains following informations:
- `reason` - Specific reason, why the error happened
- `nestedError` - Original exception/error (if available) that caused this error
- `httpStatusCode` - If the error is networking error, this property will provide HTTP status code of the error
- `httpUrlResponse` - If the error is networking errror, this will hold original HTTP response that was recieved from the backend
- `restApiError` - If the error is "well known" api error, it will be filled here
- `networkIsNotReachable` - Convenience property, if network is available (based on the error type)
- `networkConnectionIsNotTrusted` - Convenience property, if TLS error happened.
- `powerAuthErrorResponse` - When error was caused by PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - When error was caused by PowerAuth error, the error code of the error will be available here.

## License

All sources are licensed using the Apache 2.0 license. You can use them with no restrictions. 
If you are using this library, please let us know. We will be happy to share and promote your project.

## Contact

If you need any assistance, do not hesitate to drop us a line at [hello@wultra.com](mailto:hello@wultra.com) 
or our official [gitter.im/wultra](https://gitter.im/wultra) channel.

### Security Disclosure

If you believe you have identified a security vulnerability with WultraSSLPinning, 
you should report it as soon as possible via email to [support@wultra.com](mailto:support@wultra.com). Please do not post it to a public issue tracker.