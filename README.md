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
    - [Push Messages](#push-messages)
    - [Error Handling](#error-handling)
- [License](#license)
- [Contact](#contact)
    - [Security Disclosure](#security-disclosure)
<!-- end -->

## Introduction
 
With Wultra Mobile Token (WMT) SDK, you can integrate an out-of-band operation approval into an existing mobile app, instead of using a standalone mobile token application. WMT is built on top of [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk#docucheck-keep-link). It communicates with the "Mobile Token REST API" and "Mobile Push Registration API". Individual endpoints are described in the [PowerAuth Webflow documentation](https://developers.wultra.com/docs/2019.11/powerauth-webflow/).

To understand Wultra Mobile Token SDK purpose on a business level better, you can visit our own [Mobile Token application](https://www.wultra.com/mobile-token#docucheck-keep-link). We use Wultra Mobile Token SDK in our mobile token application as well.

Wultra Mobile Token SDK library does precisely this:

- Registering an existing PowerAuth activation to receive push notifications.
- Retrieving list of operations that are pending for approval for given user.
- Approving and rejecting operations with PowerAuth transaction signing.

_Note: We also provide an [Android version of this library](https://github.com/wultra/mtoken-sdk-android#docucheck-keep-link)._

## Installation

### Requirements

- iOS 10.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk#docucheck-keep-link) needs to be available in your project 

### Cocoapods

To use **WMT** in you iOS app, add the following dependencies:

```rb
pod 'WultraMobileTokenSDK/Operations', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master'
pod 'WultraMobileTokenSDK/Push', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :branch => 'master
```

_Note: If you want to use only operations, you can omit the Push dependency._

## Usage

To use this library, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, all endpoints will return an error. PowerAuth SDK implements two categories of services:

- Operations - Responsible for fetching the operation list (login request, payment, etc.), and for approving or rejecting operations.
- Push Messages - Responsible for registering the device for the push notifications.

### Operations

This part of the SDK communicates with [Mobile Token API endpoints](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Token-API.md).

#### Configuration

To create an instance of an operations service, use the following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/operations/api/")!,
    sslValidation: .default
)
let opsService = powerAuth.createWMTOperations(config: config)
```

#### Retrieve the Pending Operations

To fetch the list with pending operations, can call the `WMTOperations` API:

```swift
// TBD
```

After you retrieve the pending operations, you can render them in the UI, for example, as a list of items with a detail of operation shown after a tap:

```swift
// TBD
```

#### Start Periodic Polling

Mobile token API is highly asynchronous - to simplify the work for you, we added a convenience operation list polling feature:

```swift
// TBD
```

#### Approve or Reject Operation

Approve or reject a given operation, simply hook these actions to the approve or reject buttons:

```swift
// TBD
```

#### Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter PIN code or use biometry, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Off-line-Signatures-QR-Code.md), that is automatically processed with the SDK.

To process the operation QR code string and obtain `WMTQROperation`, simply call the `WMTQROperationParser.parse` static function:

```swift
import WultraMobileTokenSDK

guard let parsedQROperation = WMTQROperationParser.parse(string: decodedQrValue) else {
    return
}
// use parsed QR operation...
```

After that, you can produce an off-line signature using the following code:

```kotlin
```

#### Operations API Reference

All available methods and attributes of `WMTOperations` API are:

- `delegate` - Delegate object that receives info about operation loading.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `lastFetchResult()` - Cached last operations result.
- `isLoadingOperations` - Indicates if the service is loading pending operations.
- `refreshOperations` - Async "fire and forget" request to refresh pending operations.
- `getOperations(completion: @escaping GetOperationsCompletion)` - Retrieves pending operations from the server.
    - `completion` - Called when operation finishes.
- `isPollingOperations` - If the app is periodically polling for the operations from the server.
- `startPollingOperations(interval: TimeInterval)` - Starts the periodic operation polling.
    - `interval` - How often should operations be refreshed.
- `stopPollingOperations()` - Stops the periodic operation polling.
- `authorize(operation: WMTUserOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?)->Void)` - Authorize provided operation.
    - `operation` - Operation to approve, retrieved from `getOperations` call.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authorization request finishes.
- `reject(operation: WMTUserOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?)->Void)` - Reject provided operation.
    - `operation` - Operation to reject, retrieved from `getOperations` call
    - `reason` - Rejection reason
    - `completion` - Called when rejection request finishes
- `authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `operation` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authentication finishes.

For more details on the API, visit [`WMTOperations` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/WMTOperations.swift).

### Push Messages

This part of the SDK communicates with [Mobile Push Registration API](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Push-Registration-API.md).

#### Configuration

To create an instance of the push service, use the following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/push/api/")!,
    sslValidation: .default
)
let pushService = powerAuth.createWMTPush(config: config)
```

#### Registering to Push Notifications

To register an app to push notifications, you can simply call the register method:

```swift
```

#### Push Message API Reference

All available methods of the `WMTPush` API are:

- `pushNotificationsRegisteredOnServer` - If there was already made an successful request.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void)` - Registers push token on the backend.
    - `token` - token data retrieved from APNS.
    - `completionHandler` - Called when request finishes.

For more details on the API, visit [`WMTPush` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Push/WMTPush.swift).

### Error Handling

Every error produced by this library is of a `WMTError` type. This error contains the following information:

- `reason` - Specific reason, why the error happened.
- `nestedError` - Original exception/error (if available) that caused this error.
- `httpStatusCode` - If the error is networking error, this property will provide HTTP status code of the error.
- `httpUrlResponse` - If the error is networking errror, this will hold original HTTP response that was recieved from the backend.
- `restApiError` - If the error is a "well-known" API error, it will be filled here.
- `networkIsNotReachable` - Convenience property, informs about a state where the network is not available (based on the error type).
- `networkConnectionIsNotTrusted` - Convenience property, informs about a TLS error.
- `powerAuthErrorResponse` - If the error was caused by the PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - If the error was caused by the PowerAuth error, the error code of the original error will be available here.

## License

All sources are licensed using the Apache 2.0 license. You can use them with no restrictions. If you are using this library, please let us know. We will be happy to share and promote your project.

## Contact

If you need any assistance, do not hesitate to drop us a line at [hello@wultra.com](mailto:hello@wultra.com) or our official [gitter.im/wultra](https://gitter.im/wultra) channel.

### Security Disclosure

If you believe you have identified a security vulnerability with Wultra Mobile Token SDK, you should report it as soon as possible via email to [support@wultra.com](mailto:support@wultra.com). Please do not post it to a public issue tracker.
