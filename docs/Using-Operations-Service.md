# Using Operations Service

<!-- begin remove -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Retrieve Pending Operations](#retrieve-pending-operations)
- [Start Periodic Polling](#start-periodic-polling)
- [Approve an Operation](#approve-an-operation)
- [Reject an Operation](#reject-an-operation)
- [Off-line Authorization](#off-line-authorization)
- [Operations API Reference](#operations-api-reference)
- [WMTUserOperation](#WMTUserOperation)
- [Creating a Custom Operation](#creating-a-custom-operation)
- [Error handling](#error-handling)

## Introduction
<!-- end -->

Operations Service is responsible for fetching the operation list and for approving or rejecting operations.

An operation can be anything you need to be approved or rejected by the user. It can be for example money transfer, login request, access approval, ...

<!-- begin box warning -->
Note: Before using Operations Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, all endpoints will return an error
<!-- end -->

Operations Service communicates with a backend via [Mobile Token API endpoints](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Token-API.md).

## Creating an Instance

### On Top of the `PowerAuthSDK` instance
```swift
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

let networkingConfig = WPNConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/operations/api/")!,
    sslValidation: .default
)
// powerAuth is instance of PowerAuthSDK
let opsService = powerAuth.createWMTOperations(networkingConfig: networkingConfig, pollingOptions: [.pauseWhenOnBackground])
```

### On Top of the `WPNNetworkingService` instance
```swift
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

// networkingService is instance of WPNNetworkingService
let opsService = networkingService.createWMTOperations(pollingOptions: [.pauseWhenOnBackground])
```

The `pollingOptions` parameter is used for polling feature configuration. The default value is empty `[]`. Possible options are:

- `WMTOperationsPollingOptions.pauseWhenOnBackground`

### With custom WMTUserOperation objects

To retreive custom user operations, both `createWMTOperations` methods offer optional parameter `customUserOperationType` where you can setup requested type.

```swift
// networkingService is instance of WPNNetworkingService
let opsService = networkingService.createWMTOperations(customUserOperationType: CustomUserOperation.self).
```

When [custom operation type](#subclassing-WMTUserOperation) is set, all `WMTUserOperation` objects from such service can be explicitly unboxed to this type.

## Retrieve Pending Operations

To fetch the list with pending operations, can call the `WMTOperations` API:

```swift
import WultraMobileTokenSDK

DispatchQueue.main.async {
    // This method needs to be called on the main thread.
    operationsService.getOperations { result in
        switch result {
        case .success(let ops):
            // render success UI
        case .failure(let err):
            // render error UI
        }
    }
}
```

After you retrieve the pending operations, you can render them in the UI, for example, as a list of items with a detail of operation shown after a tap.

<!-- begin box warning -->
Note: Language of the UI data inside the operation depends on the configuration of the `WMTOperation.acceptLanguage`.
<!-- end -->

## Start Periodic Polling

Mobile token API is highly asynchronous - to simplify the work for you, we added a convenience operation list polling feature:

```swift
import WultraMobileTokenSDK

// fetch new operations every 7 seconds periodically
if (!operationsService.isPollingOperations) {
    operationsService.startPollingOperations(interval: 7, delayStart: false)
}
```

To receive the result of the polling, set up a delegate.

<!-- begin box warning -->
Note that the listener is called for all "fetch operations" requests (not just the polling).
<!-- end -->

```swift
import WultraMobileTokenSDK
import PowerAuth2

class MyOperationsManager: WMTOperationsDelegate {

    private let ops: WMTOperations

    init(powerAuth: PowerAuthSDK) {
        let networkingConfig = WPNConfig(
            baseUrl: URL(string: "https://myservice.com/mtoken/operations/api/")!,
            sslValidation: .default
        )
        self.ops = powerAuth.createWMTOperations(networkingConfig: networkingConfig)
        self.ops.delegate = self
    }

    func operationsFailed(error: WMTError) {
        // show UI that the last fetch has failed
    }

    func operationsChanged(operations: [UserOperation], removed: [UserOperation], added: [UserOperation]) {
        // refresh operation list UI
    }

    func operationsLoading(loading: Bool) {
        // show loading UI
    }
}
```

<!-- begin box info -->
Polling behavior can be adjusted by the `pollingOptions` parameter when [creating an instance](#creating-an-instance) of the service.
<!-- end -->

## Approve an Operation

To approve an operation use `WMTOperations.authorize`. You can simply use it with following examples:

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Approve operation with password
func approve(operation: WMTOperation, password: String) {

    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)

    operationService.authorize(operation: operation, authentication: auth) { error in
        if let error = error {
            // show error UI
        } else {
            // show success UI
        }
    }
}
```

To approve offline operations with biometry, your PowerAuth instance [need to be configured with biometry factor](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#biometry-setup).

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Approve operation with password
func approveWithBiometry(operation: WMTOperation) {

    let auth = PowerAuthAuthentication.possessionWithBiometry(prompt: "Confirm operation.")

    operationService.authorize(operation: operation, authentication: auth) { error in
        if let error = error {
            // show error UI
        } else {
            // show success UI
        }
    }
}
```

## Reject an Operation

To reject an operation use `WMTOperations.reject`. Operation rejection is confirmed by possession factor so there is no need for creating  `PowerAuthAuthentication` object. You can simply use it with the following example.

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Reject operation with some reason
func reject(operation: WMTOperation, reason: WMTRejectionReason) {
    operationService.reject(operation: operation, reason: reason) { error in
        if let error = error {
            // show error UI
        } else {
            // show success UI
        }
    }
}
```

## Operation History

You can retrieve an operation history via the `WMTOperations.getHistory` method. The returned result is operations and their current status.

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Retrieve operation history with password
func history(password: String) {
    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)
    operationService.getHistory(authentication: auth) { result in
        switch result {
        case .success(let operations):
            // process operation history
            break
        case .failure(let error):
            // process error
            break
        }
    }
}
```

<!-- begin box warning -->
Note that the operation history availability depends on the backend implementation and might not be available. Please consult this with your backend developers.
<!-- end -->

## Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter PIN code or use biometry, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Off-line-Signatures-QR-Code.md), that is automatically processed with the SDK.

### Processing Scanned QR Operation

```swift
import WultraMobileTokenSDK

let code = "..." // scanned QR value
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

### Authorizing Scanned QR Operation

<!-- begin box info -->
An offline operation needs to be __always__ approved with __2-factor scheme__ (password or biometry).
<!-- end -->

<!-- begin box info -->
Each offline operation created on the server has an __URI ID__ to define its purpose and configuration. The default value used here is `/operation/authorize/offline` and can be modified with the `uriId` parameter in the `authrorize` method.
<!-- end -->

#### With Password

```swift
import WultraMobileTokenSDK
import PowerAuth2

func approveQROperation(operation: WMTQROperation, password: String) {

    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)

    operationsService.authorize(qrOperation: operation, authentication: auth) { result in
        switch result {
        case .success(let code):
            // Display the signature to the user so it can be manually rewritten.
            // Note that the operation will be signed even with a wrong password!
        case .failure(let error):
            // Failed to sign the operation
        }
    }
}
```

<!-- begin box info -->
An offline operation can and will be signed even with an incorrect password. The signature cannot be used for manual approval in such a case. This behavior cannot be detected, so you should warn the user that an incorrect password will result in an incorrect "approval code".
<!-- end -->

#### With Password and Custom `uriId`

```swift
import WultraMobileTokenSDK
import PowerAuth2

func approveQROperation(operation: WMTQROperation, password: String) {

    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)

    // using the authorize method with custom uriId
    operationsService.authorize(qrOperation: operation, uriId: "/confirm/offline/operation", authentication: auth) { result in
        switch result {
        case .success(let code):
            // Display the signature to the user so it can be manually rewritten.
            // Note that the operation will be signed even with a wrong password!
        case .failure(let error):
            // Failed to sign the operation
        }
    }
}
```

#### With Biometry

To approve offline operations with biometry, your PowerAuth instance [need to be configured with biometry factor](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#biometry-setup).

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Approves QR operation with biometry
func approveQROperationWithBiometry(operation: WMTQROperation) {

    guard operation.flags.allowBiometryFactor else {
        // biometry usage is not allowed on this operation
        return
    }

    let auth = PowerAuthAuthentication.possessionWithBiometry(prompt: "Confirm operation.")

    operationsService.authorize(qrOperation: operation, authentication: auth) { result in
        switch result {
        case .success(let code):
            // Display the signature to the user so it can be manually rewritten.
        case .failure(let error):
            // Failed to sign the operation
        }
    }
}
```

## Operations API Reference

All available methods and attributes of `WMTOperations` API are:

- `delegate` - Delegate object that receives info about operation loading. Methods of the delegate are always called on the main thread.
- `acceptLanguage` - Language settings, that will be sent along with each request. The server will return properly localized content based on this value. Value follows standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5)
- `lastFetchResult()` - Cached last operations result.
- `isLoadingOperations` - Indicates if the service is loading pending operations.
- `refreshOperations` - Async "fire and forget" request to refresh pending operations.
- `getOperations(completion: @escaping GetOperationsCompletion)` - Retrieves pending operations from the server.
    - `completion` - Called when operation finishes. Always called on the main thread.
- `isPollingOperations` - If the app is periodically polling for the operations from the server.
- `pollingOptions` - Configuration of the polling feature
    - `pauseWhenOnBackground` - Polling will be paused when your app is on the background.
- `startPollingOperations(interval: TimeInterval, delayStart: Bool)` - Starts the periodic operation polling.
    - `interval` - How often should operations be refreshed.
    - `delayStart` - When true, polling starts after the first `interval` time passes.
- `stopPollingOperations()` - Stops the periodic operation polling.
- `authorize(operation: WMTOperation, with: PowerAuthAuthentication, completion: @escaping(Result<Void, WMTError>) -> Void)` - Authorize provided operation.
    - `operation` - An operation to approve, retrieved from `getOperations` call or [created locally](#creating-a-custom-operation).
    - `with` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authorization request finishes. Always called on the main thread.
- `reject(operation: WMTOperation, with: WMTRejectionReason, completion: @escaping(Result<Void, WMTError>) -> Void)` - Reject provided operation.
    - `operation` - An operation to reject, retrieved from `getOperations` call or [created locally](#creating-a-custom-operation).
    - `with` - Rejection reason
    - `completion` - Called when rejection request finishes. Always called on the main thread.
- `getHistory(authentication: PowerAuthAuthentication, completion: @escaping(Result<[WMTOperationHistoryEntry],WMTError>) -> Void)` - Retrieves operation history
  - `authentication` - PowerAuth authentication object for operation signing.
  - `completion` - Called when rejection request finishes. Always called on the main thread.
- `authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `qrOperation ` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authentication finishes. Always called on the main thread.
- `authorize(qrOperation: WMTQROperation, uriId: String, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `qrOperation ` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
    - `uriId` - Custom signature URI ID of the operation. Use URI ID under which the operation was created on the server. Usually something like `/confirm/offline/operation`.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authentication finishes. Always called on the main thread.

## WMTUserOperation

Operations objects retrieved through the `getOperations` API method are called "user operations".

Under this abstract name, you can imagine for example "Login operation", which is a request for signing in to the online account in a web browser on another device. **In general, it can be any operation that can be either approved or rejected by the user.**

Visually, the operation should be displayed as an info page with all the attributes (rows) of such operation, where the user can decide if he wants to approve or reject it.

Definition of the `WMTUserOperation`:

```swift
class WMTUserOperation: WMTOperation {

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
- `AMOUNT` like "100.00 CZK"  
- `KEY_VALUE` any key value pair  
- `NOTE` just like `KEY_VALUE`, emphasizing that the value is a note or message  
- `HEADING` single highlighted text, written in a larger font, used as a section heading  
- `PARTY_INFO` providing structured information about third-party data (for example known e-shop)

### Subclassing WMTUserOperation

`WMTUserOperation` class is `open` and can be subclassed. This is useful when your backend adds additional properties to operations retrieved via the `getOperations` API.

Example of such class:

```swift
class CustomUserOperation: WMTUserOperation {
    
    enum CodingKeys: CodingKey {
        case playSound
    }
    
    /// Should we play a sound when the operation is displayed?
    let playSound: Bool
    
    required init(from decoder: Decoder) throws {
	    /// Decode the playSound property
        playSound = try decoder.container(keyedBy: CodingKeys.self).decode(Bool, forKey: . playSound)
        /// Decode the rest of the properties by the super class
        try super.init(from: decoder)
}
```

To set up the Operation Service to receive such objects, you need to create it with a [`customUserOperationType` parameter](#with-custom-WMTUserOperation-objects). After that, all `WMTUserOperation` objects can be unboxed into your custom objects.

Example of the unboxing:

```swift
opsService.getOperations { result in
    switch result {
    case .success(let ops):
       // unbox operations into the [CustomUserOperation]
    	let unboxed = ops.map { $0 as! CustomUserOperation }
    case .failure(let error):
    	// do something with the error
    	break
    }
}
```

## Creating a Custom Operation

In some specific scenarios, you might need to approve or reject an operation that you received through a different channel than `getOperations`. In such cases, you can implement the `WMTOperation` protocol in your custom class and then feed created objects to both `authorize` and `reject` methods.

<!-- begin box success -->
You can use concrete convenient class `WMTLocalOperation`, that implements the `WMTOperation` protocol.
<!-- end -->

Definition of the `WMTOperation`:

```swift
public protocol WMTOperation {

    /// Operation identifier
    var id: String { get }

    /// Data for signing
    var data: String { get }
}
```

## Error handling

Every error produced by the Operations Service is of a `WMTError` type. For more information see detailed [error handling documentation](Error-Handling.md).
