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
 
With Wultra Mobile Token (WMT) SDK, you can integrate an out-of-band operation approval into an existing mobile app, instead of using a standalone mobile token application. WMT is built on top of [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk). It communicates with the "Mobile Token REST API" and "Mobile Push Registration API". Individual endpoints are described in the [PowerAuth Webflow documentation](https://github.com/wultra/powerauth-webflow/).

To understand Wultra Mobile Token SDK purpose on a business level better, you can visit our own [Mobile Token application](https://www.wultra.com/mobile-token#docucheck-keep-link). We use Wultra Mobile Token SDK in our mobile token application as well.

Wultra Mobile Token SDK library does precisely this:

- Registering an existing PowerAuth activation to receive push notifications.
- Retrieving list of operations that are pending for approval for given user.
- Approving and rejecting operations with PowerAuth transaction signing.

_Note: We also provide an [Android version of this library](https://github.com/wultra/mtoken-sdk-android)._

## Installation

### Requirements

- iOS 10.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) needs to be available in your project 

### Cocoapods

To use **WMT** in you iOS app, add the following dependencies:

```rb
pod 'WultraMobileTokenSDK/Operations', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :tag => '1.0.1'
pod 'WultraMobileTokenSDK/Push', :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :tag => '1.0.1'
```

_Note: This documentation is using version `1.0.1` as an example. You can find the latest version at [github's release](https://github.com/wultra/mtoken-sdk-ios/releases#docucheck-keep-link) page._
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
import WultraMobileTokenSDK

operationsService.getOperations { result in
    switch result {
    case .success(let ops):
        // render success UI
    case .failure(let err):
        // render error UI
    }
}
```

After you retrieve the pending operations, you can render them in the UI, for example, as a list of items with a detail of operation shown after a tap.

*Note: Language of the UI data inside the operation depends on the cofiguration of the `WMTOperation.acceptLanguage`.*

#### Start Periodic Polling

Mobile token API is highly asynchronous - to simplify the work for you, we added a convenience operation list polling feature:

```swift
import WultraMobileTokenSDK

// fetch new operations every 7 seconds periodically
if (!operationsService.isPollingOperations) {
    operationsService.startPollingOperations(interval: 7)
}
```

Polling results are reported to `WMTOperations.delegate`.

#### Approve or Reject Operation

Approve or reject a given operation, simply hook these actions to the approve or reject buttons:

```swift
import WultraMobileTokenSDK

func approve(operation: WMTUserOperation, password: String) {

    let authentication = PowerAuthAuthentication()
    authentication.usePossession = true
    authentication.usePassword = password

    operationService.authorize(operation: operation, authentication: authentication) { error in 
        if let error = error {
            // show error UI
        } else {
            // show success UI
        }
    }
}

func reject(operation: WMTUserOperatio, reason: WMTRejectionReason) {
    operationService.reject(operation: operation, reason: reason) { error in 
        if let error = error {
            // show error UI
        } else {
            // show success UI
        }
    }
}
```

#### Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter PIN code or use biometry, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Off-line-Signatures-QR-Code.md), that is automatically processed with the SDK.

To process the operation QR code string and obtain `WMTQROperation`, simply call the `WMTQROperationParser.parse` function:

```swift
import WultraMobileTokenSDK

let qrPayload = "..." // scanned QR value
let parser = WMTQROperationParser()
switch parser.parse(string: code) {
case .success(let op):
    let isMasterKey = op.signature.signingKey == .master
    guard powerAuth.verifyServerSignedData(op.signedData, signature: op.signature.signature, masterKey: isMasterKey) else {
        // failed to verify signature
        return
    }
    // opeartion is parsed and verify
case .failure(let error):
    // failed to parse. See error for more info.
}
```

After that, you can produce an off-line signature using the following code:

```swift
import WultraMobileTokenSDK

func approveQROperation(operation: WMTQROperation, password: String) {

    let authentication = PowerAuthAuthentication()
    authentication.usePossession = true
    authentication.usePassword = password
    authentication.useBiometry = false

    operationsService.authorize(qrOperation: operation, authentication: authentication) { result in 
        switch result {
        case .success(let code):
            // show success UI - display the code to the user
            // note that operation will be successful even with a wrong
            // password as it cannot be verified on the server
        case .failure(let error):
            // show error UI
        }
    }
}
```

#### Operations API Reference

All available methods and attributes of `WMTOperations` API are:

- `delegate` - Delegate object that receives info about operation loading.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request. The server will return properly localized content based on this value. Value follows standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5)
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

For more details on the API, visit [`WMTOperations` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/WMTOperations.swift#docucheck-keep-link).

#### WMTUserOperation

Operations objects retrieved through the online API (like `getOperations` method in `WMTOperations`) are called "user operations".

Under this abstract name, you can imagine for example "Login operation", which is a request for signing in to the online account in a web browser on another device. **In general, it can be any operation that can be either approved or rejected by the user.**

Visually, the operation should be displayed as an info page with all the attributes (rows) of such operation, where the user can decide if he wants to approve or reject it.

Definition of the `WMTUserOperation`:

```swift
class WMTUserOperation {

	/// Unique operation identifier
	public let id: String
	    
	/// System name of the operation.
	///
	/// This property lets you adjust the UI for various operation types. 
	/// For example, the "login" operation may display a specialized interface with 
	/// an icon or an illustration, instead of an empty list of attributes, 
	/// "payment" operation can include a special icon that denotes payments, etc.
	public let name: String
	    
	/// Actual data that will be signed.
	public let data: String
	    
	/// Date and time when the operation was created.
	public let operationCreated: Date
	    
	/// Date and time when the operation will expire.
	public let operationExpires: Date
	    
	/// Data that should be presented to the user.
	public let formData: WMTOperationFormData
	    
	/// Allowed signature types.
	///
	/// This hints if the operation needs a 2nd factor or can be approved simply by 
	/// tapping an approve button. If the operation requires 2FA, this value also hints if 
	/// the user may use the biometry, or if a password is required.
	public let allowedSignatureType: WMTAllowedOperationSignature
}
```

Definition of `WMTOperationFormData`: 

```swift
public class WMTOperationFormData {
    
    /// Title of the operation
    public let title: String
    
    /// Message for the user
    public let message: String
    
    /// Other attributes.
    ///
    /// Each attribute presents one line in the UI. Attributes are differentiated by type property
    /// and specific classes such as WMTOperationAttributeNote or WMTOperationAttributeAmount.
    public let attributes: [WMTOperationAttribute]
}
```

Attributes types:  
- `amount` like "100.00 CZK"  
- `keyValue` any key value pair  
- `note` just like keyValue, emphasizing that the value is a note or message  
- `heading` single highlighted text, written in a larger font, used as a section heading  
- `partyInfo` providing structured information about third party data (for example known eshop)

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
// AppDelegate method
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    pushService.registerDeviceTokenForPushNotifications(token: deviceToken) { success, error in
        if !success {
            // do something with theerror
        }
    }
}
```

#### Push Message API Reference

All available methods of the `WMTPush` API are:

- `pushNotificationsRegisteredOnServer` - If there was already made an successful request.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void)` - Registers push token on the backend.
    - `token` - token data retrieved from APNS.
    - `completionHandler` - Called when request finishes.

For more details on the API, visit [`WMTPush` code documentation](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Push/WMTPush.swift#docucheck-keep-link).

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
