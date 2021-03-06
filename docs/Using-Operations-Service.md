# Using Operations Service

<!-- begin TOC -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Retrieve Pending Operations](#retrieve-pending-operations)
- [Start Periodic Polling](#start-periodic-polling)
- [Approve an Operation](#approve-an-operation)
- [Reject an Operation](#reject-an-operation)
- [Off-line Authorization](#off-line-authorization)
- [Operations API Reference](#operations-api-reference)
- [Creating a Custom Operation](#creating-a-custom-operation)
- [Error handling](#error-handling)
<!-- end -->

## Introduction

Operations Service is responsible for fetching the operation list and for approving or rejecting operations.

An operation can be anything you need to be approved or rejected by the user. It can be for example money transfer, login request, access approval, ...

> __Note:__ Before using Operations Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, all endpoints will return an error

Operations Service communicates with a backend via [Mobile Token API endpoints](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Token-API.md).

## Creating an Instance

To create an instance of an operations service, use the following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/operations/api/")!,
    sslValidation: .default
)
let opsService = powerAuth.createWMTOperations(config: config)
```

`sslValidation` property is used when validating HTTPS requests. Following strategies can be used.  

- `WMTSSLValidationStrategy.default` 
- `WMTSSLValidationStrategy.noValidation`
- `WMTSSLValidationStrategy.sslPinning` 

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

*Note: Language of the UI data inside the operation depends on the cofiguration of the `WMTOperation.acceptLanguage`.*

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

_Note that the listener is called for all "fetch operations" requests (not just the polling)._

```swift
import WultraMobileTokenSDK

class MyOperationsManager: WMTOperationsDelegate {

    private let ops: WMTOperations
    
    init(powerAuth: PowerAuthSDK) {
        let opsConfig = WMTConfig(
            baseUrl: URL(string: "https://myservice.com/mtoken/api/")!,
            sslValidation: .default)
        self.ops = powerAuth.createWMTOperations(config: opsConfig)
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

## Approve an Operation

To approve an operation use `WMTOperations.authorize`. You can simply use it with the following example:

```swift
import WultraMobileTokenSDK

func approve(operation: WMTOperation, password: String) {

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
```

## Reject an Operation

To reject an operation use `WMTOperations.reject`. Operation rejection is confirmed by possession factor so there is no need for creating  `PowerAuthAuthentication` object. You can simply use it with the following example.

```swift
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

## Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter PIN code or use biometry, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Off-line-Signatures-QR-Code.md), that is automatically processed with the SDK.

To process the operation QR code string and obtain `WMTQROperation`, simply call the `WMTQROperationParser.parse` function:

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

## Operations API Reference

All available methods and attributes of `WMTOperations` API are:

- `delegate` - Delegate object that receives info about operation loading. Methods of the delegate are always called on the main thread.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request. The server will return properly localized content based on this value. Value follows standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5)
- `lastFetchResult()` - Cached last operations result.
- `isLoadingOperations` - Indicates if the service is loading pending operations.
- `refreshOperations` - Async "fire and forget" request to refresh pending operations.
- `getOperations(completion: @escaping GetOperationsCompletion)` - Retrieves pending operations from the server.
    - `completion` - Called when operation finishes. Always called on the main thread.
- `isPollingOperations` - If the app is periodically polling for the operations from the server.
- `startPollingOperations(interval: TimeInterval, delayStart: Bool)` - Starts the periodic operation polling.
    - `interval` - How often should operations be refreshed.
    - `delayStart` - When true, polling starts after the first `interval` time passes.
- `stopPollingOperations()` - Stops the periodic operation polling.
- `authorize(operation: WMTOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?)->Void)` - Authorize provided operation.
    - `operation` - An operation to approve, retrieved from `getOperations` call or [created locally](#creating-a-custom-operation).
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authorization request finishes. Always called on the main thread.
- `reject(operation: WMTOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?)->Void)` - Reject provided operation.
    - `operation` - An operation to reject, retrieved from `getOperations` call or [created locally](#creating-a-custom-operation).
    - `reason` - Rejection reason
    - `completion` - Called when rejection request finishes. Always called on the main thread.
- `authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `operation` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
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
- `PARTY_INFO` providing structured information about third-party data (for example known eshop)

## Creating a Custom Operation

In some specific scenarios, you might need to approve or reject an operation that you received through a different channel than `getOperations`. In such cases, you can implement the `WMTOperation` protocol in your custom class and then feed created objects to both `authorize` and `reject` methods.

_Note: For such cases, you can use concrete convenient class `WMTLocalOperation`, that implements this protocol._

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
