# Using Operations Service

<!-- begin remove -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Retrieve Pending Operations](#retrieve-pending-operations)
- [Start Periodic Polling](#start-periodic-polling)
- [Approve an Operation](#approve-an-operation)
- [Reject an Operation](#reject-an-operation)
- [Mobile Token Data](#mobile-token-data)
- [Operation detail](#operation-detail)
- [Claim the Operation](#claim-the-operation)
- [Operation History](#operation-history)
- [Cancelling Operations](#cancelling-operations)
- [Off-line Authorization](#off-line-authorization)
- [Operations API Reference](#operations-api-reference)
- [WMTUserOperation](#wmtuseroperation)
- [Creating a Custom Operation](#creating-a-custom-operation)
- [WMTProximityCheck](#wmtproximitycheck)
- [Error handling](#error-handling)

## Introduction
<!-- end -->

The Operations Service is responsible for fetching the operation list and for approving or rejecting operations.

An operation can be anything you need to be approved or rejected by the user. It can be for example money transfer, login request, access approval, ...

<!-- begin box warning -->
Note: Before using Operations Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, all endpoints will return an error
<!-- end -->

Operations Service communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Creating an Instance

The preferred way of instantiating Operations Service is via `WultraMobileToken` class.
See: [Example Usage](./Example-Usage)

### Customized initialization

In case you need to create more customized instance. You can do so with an initializer. We will need to define networking configuration and provide PowerAuthSDK instance.

```swift
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

let networkingConfig = WPNConfig(
    baseUrl: URL(string: "https://powerauth.myservice.com/enrollment-server")!,
    sslValidation: .default
)

let networkingService = WPNNetworkingService(
    powerAuth: powerAuth,
    config: networkingConfig,
    serviceName: "OperationsService",
    acceptLanguage: "en"
)

let opsService = WMTOperations(networking: networkingService)
```


## Retrieve Pending Operations

Note: All async/throws methods shown here also have callback-based counterparts (`completion: @escaping (Result<…, WMTError>) -> Void`) if you prefer the closure style.

To fetch the list with pending operations, can call the `WMTOperations` API:

```swift
import WultraMobileTokenSDK

Task { @MainActor in
    // This method needs to be called on the main thread.
    do {
        let ops = try await operationsService.getOperations()
        // render success UI
    } catch {
        // render error UI
    }
}
```

After you retrieve the pending operations, you can render them in the UI, for example, as a list of items with a detail of the operation shown after a tap.

<!-- begin box warning -->
Note: The language of the UI data inside the operation depends on the configuration of the `WMTOperation.acceptLanguage`.
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

### Default and Minimum TimeInterval Enforcement

For convenience, there is a default implementation where you can omit the polling interval and it is automatically set to 7 seconds. If you specify an interval below 5 seconds, it will be automatically adjusted to 5 seconds to prevent server overload.

### Setting up a delegate

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
            baseUrl: URL(string: "https://powerauth.myservice.com/enrollment-server")!,
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

### Best Practices and Recommendations

For optimal server performance, consider adjusting polling intervals based on your application's requirements. For instance, when push notifications are enabled, it's advisable to double the polling interval to minimize server load.

## Approve an Operation

To approve an operation use `WMTOperations.authorize`. You can simply use it with the following examples:

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Approve operation with password
func approve(operation: WMTOperation, password: String) {

    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)

    Task {
        do {
            try await operationService.authorize(operation: operation, with: auth)
            // show success UI
        } catch {
            // show error UI
        }
    }
}
```

To approve offline operations with biometry, your PowerAuth instance [needs to be configured with biometry factor](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#biometry-setup).

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Approve operation with biometry
func approveWithBiometry(operation: WMTOperation) {

    let auth = PowerAuthAuthentication.possessionWithBiometry(prompt: "Confirm operation.")

    Task {
        do {
            try await operationService.authorize(operation: operation, with: auth)
            // show success UI
        } catch {
            // show error UI
        }
    }
}
```

## Reject an Operation

To reject an operation use `WMTOperations.reject`. Operation rejection is confirmed by a possession factor, so there is no need for creating a `PowerAuthAuthentication` object. You can simply use it with the following example.

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Reject operation with some reason
func reject(operation: WMTOperation, reason: WMTRejectionReason) {
    Task {
        do {
            try await operationService.reject(operation: operation, with: reason)
            // show success UI
        } catch {
            // show error UI
        }
    }
}
```


## Mobile Token Data

With PowerAuth Server **1.10+**, you can attach additional, customer-specific metadata during operation authorization via `mobileTokenData`.  
Since PowerAuth Server **2.0+**, you can also pass `mobileTokenData` when rejecting an operation.

This is especially useful for **fraud detection systems (FDS)**, risk scoring, or other backend-specific logic.

You can provide this data in two ways:

---

### Direct Dictionary Approach

If you already have a static set of key–value pairs, build a `[String: Encodable]` dictionary and assign it to the operation:

```swift
// Example: directly attaching a static dictionary of metadata
let fdsData: [String: Encodable] = [
    "deviceFingerprint": "abc123def456",
    "riskScore": 0.8,
    "location": [
        "latitude": 50.0755,
        "longitude": 14.4378
    ]
]

operation.mobileTokenData = fdsData

let auth = PowerAuthAuthentication.possessionWithPassword(password: "password123")
Task {
    do {
        try await operationsService.authorize(operation: operation, with: auth)
        // Operation approved successfully
    } catch {
        // Handle network or SDK error
        print(error)
    }
}
```

---

### Builder-Based Approach

For **dynamic, structured, or multi-step** data, use `WMTMobileTokenData.Builder`.

The builder offers a thread-safe API for collecting and organizing entries before producing the final dictionary for submission.

#### WMTMobileTokenData Builder

- **Initialize** with optional `initialData: [String: Encodable]`.
- **Add generic entries** using `put(_ key: String, _ value: Encodable)`.
- **Attach structured records** (e.g., `WMTPreApprovalScreensRecorder`) using `put(_ record: WMTMobileTokenDataRecord)`.
- **Extend** with your own record types by conforming to `WMTMobileTokenDataRecord`.

##### Example

```swift
// Optional initial data entries (e.g., FDS hints)
let initialData: [String: Encodable] = ["deviceFingerprint": "abc123"]

// Create the builder
let builder = WMTMobileTokenData.Builder(initialData: initialData)

// Add generic entries
builder.put("riskScore", 0.82)

// Assign to the operation right before approve/reject
operation.mobileTokenData = builder.build()
```

---

### Record Helpers

Sometimes your `mobileTokenData` isn’t just a couple of fields — it’s a **structured section** (e.g., a timeline of user actions or device events).  
For this, the SDK exposes the `WMTMobileTokenDataRecord` protocol.

#### The `WMTMobileTokenDataRecord` Protocol

A record contributes one **top-level entry** (a single key and its value) to the final `mobileTokenData` dictionary.

- `key` — the top-level field name under which your record appears
- `build()` — returns the **value** (any `Encodable`) for that key

```swift
public protocol WMTMobileTokenDataRecord {
    /// Top-level key under which this record is stored.
    var key: String { get }

    /// Produces the value to be stored for `key`.
    /// Called by the builder during `put(record)`.
    func build() -> Encodable
}
```

---

##### Example: Custom Record

Create your own record for any structured section — for example, app configuration flags.

```swift
final class CustomRecord: WMTMobileTokenDataRecord {
    static let key = "customSection"
    var key: String { Self.key }

    private var data: [String: Encodable] = [:]

    @discardableResult
    func add(_ name: String, _ value: Encodable) -> Self {
        data[name] = value
        return self
    }

    func build() -> Encodable {
        data // value snapshot
    }
}

// Usage
let builder = WMTMobileTokenData.Builder()
let record = CustomRecord()
    .add("flag", true)
    .add("mode", "debug")

// Either pass the whole record…
builder.put(record)
// …or manually by key/value (equivalent):
// builder.put(record.key, record.build())

operation.mobileTokenData = builder.build()
```

---

#### Predefined Record Helper: `WMTPreApprovalScreensRecorder`

The SDK includes `WMTPreApprovalScreensRecorder`, which records how users move through **Pre-Approval screens**.

Each recorded **visit** contains:
- `screen` (identifier)
- `timestampOpened`
- `timestampClosed`
- `action` (`CONTINUE`, `CLOSE`, `REJECT`, `SCAN`, or a custom string)

Timestamps are aligned with server time via `PowerAuthSDK.timeSynchronizationService` (when available).

The recorder exposes few methods:

- `begin(_ id: String)` — starts a new visit for the given screen ID.  
  If a different visit is open, that previous visit is finalized *without* a closing timestamp or action.

- `end(_ id: String, action: ScreenAction)` — closes the current visit if the `id` matches.  
  If there’s no open visit, but the most recent recorded visit has the same `id` and is still unclosed, it is finalized instead.
  
- `reset()` - resets recorded visits

#### Example

```swift
// Create the builder used to assemble mobileTokenData
let builder = WMTMobileTokenData.Builder()

// Recorder for the Pre-Approval flow.
// PowerAuthSDK provides server-aligned time via timeSynchronizationService.
let recorder = WMTPreApprovalScreensRecorder(powerAuthSDK: pa)

// As the user navigates Pre-Approval screens:
recorder.begin("intro-warning")
// ... user reads content ...
recorder.end("intro-warning", action: .close)

recorder.begin("intro-warning")
recorder.end("intro-warning", action: .continue)

recorder.begin("qr")
recorder.end("qr", action: .scan)

// When your Pre-Approval flow is finished, attach the recorder to the builder
builder.put(recorder)

// Assign to the operation right before approve/reject
operation.mobileTokenData = builder.build()
```

---

The `mobileTokenData` is completely optional and the structure is customer-specific. If you don't need this functionality, you can continue using operations without providing this property.

## Operation detail

To get a detail of an operation based on operation ID use `WMTOperations.getDetail`. Operation detail is confirmed by the possession factor so there is no need for creating  `PowerAuthAuthentication` object. The returned result is the operation and its current status.

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Retrieve operation details based on the operation ID.
func getDetail(operationId: String) {
    Task {
        do {
            let operation = try await operationService.getDetail(operationId: operationId)
            // process operation
        } catch {
            // process error
        }
    }
}
```

## Claim the Operation

To claim a non-persolized operation use `WMTOperations.claim`. 

A non-personalized operation refers to an operation that is initiated without a specific userId. In this state, the operation is not tied to a particular user. 

Operation claim is confirmed by the possession factor so there is no need for creating a `PowerAuthAuthentication` object. The returned result is the operation and its current status and also the claimed operation **is inserted into the operation list**. You can simply use it with the following example.

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Assigns the 'non-personalized' operation to the user
func claim(operationId: String) {
    Task {
        do {
            let operation = try await operationService.claim(operationId: operationId)
            // process operation
        } catch {
            // process error
        }
    }
}
```

## Operation History

You can retrieve an operation history via the `WMTOperations.getHistory` method. The returned result is operations

```swift
import WultraMobileTokenSDK
import PowerAuth2

// Retrieve operation history with password
func history(password: String) {
    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)
    Task {
        do {
            let operations = try await operationService.getHistory(authentication: auth)
            // process operation history
        } catch {
            // process error
        }
    }
}
```

<!-- begin box warning -->
Note that the operation history availability depends on the backend implementation and might not be available. Please consult this with your backend developers.
<!-- end -->

## Cancelling Operations

With async/throws APIs, keep the Swift `Task` that performs the request and cancel it when needed.

You can do so as shown below:

```swift
let task = Task { @MainActor in
    do {
        _ = try await operationsService.getOperations()
    } catch {
        // handle error
    }
}
task.cancel()
```

For more examples refer to `IntegrationTests` in this repository.


## Off-line Authorization

In case the user is not online, you can use off-line authorizations. In this operation mode, the user needs to scan a QR code, enter a PIN code, or use biometrics, and rewrite the resulting code. Wultra provides a special format for [the operation QR codes](https://github.com/wultra/enrollment-server/blob/develop/docs/Offline-Signatures-QR-Code.md), which are automatically processed with the SDK.

### Processing Scanned QR Operation

You can verify the QR operation signature automatically during parsing by passing a `PowerAuthSDK` instance to the parser. If the signature is invalid, parsing fails with `signatureVerificationFailed`:

```swift
import WultraMobileTokenSDK

let code = "..." // scanned QR value
let parser = WMTQROperationParser(powerAuth: powerAuth)
switch parser.parse(string: code) {
case .success(let op):
    // operation is parsed and signature is verified
case .failure(let error):
    // failed to parse or verify. See the error for more info.
}
```

Alternatively, you can create a parser without `PowerAuthSDK` and verify the signature manually:

```swift
import WultraMobileTokenSDK

let code = "..." // scanned QR value
let parser = WMTQROperationParser()
switch parser.parse(string: code) {
case .success(let op):
    do {
        try op.verifySignature(for: powerAuth)
        // or equivalently:
        // try powerAuth.verifyDigitalSignature(of: op)
    } catch {
        // failed to verify signature
        return
    }
    // operation is parsed and verified
case .failure(let error):
    // failed to parse. See the error for more info.
}
```

### Authorizing Scanned QR Operation

<!-- begin box info -->
An offline operation needs to be __always__ approved with __a 2-factor scheme__ (password or biometry).
<!-- end -->

<!-- begin box info -->
Each offline operation created on the server has an __URI ID__ to define its purpose and configuration. The default value used here is `/operation/authorize/offline` and can be modified with the `uriId` parameter in the `authorize` method.
<!-- end -->

#### With Password

```swift
import WultraMobileTokenSDK
import PowerAuth2

func approveQROperation(operation: WMTQROperation, password: String) {

    let auth = PowerAuthAuthentication.possessionWithPassword(password: password)

    Task {
        do {
            let code = try await operationsService.authorize(qrOperation: operation, authentication: auth)
            // Display the signature to the user so it can be manually rewritten.
            // Note that the operation will be signed even with a wrong password!
        } catch {
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

    Task {
        do {
            // using the authorize method with custom uriId
            let code = try await operationsService.authorize(qrOperation: operation, uriId: "/confirm/offline/operation", authentication: auth)
            // Display the signature to the user so it can be manually rewritten.
            // Note that the operation will be signed even with a wrong password!
        } catch {
            // Failed to sign the operation
        }
    }
}
```

#### With Biometry

To approve offline operations with biometry, your PowerAuth instance [needs to be configured with biometry factor](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#biometry-setup).

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

    Task {
        do {
            let code = try await operationsService.authorize(qrOperation: operation, authentication: auth)
            // Display the signature to the user so it can be manually rewritten.
        } catch {
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
- `currentServerDate` - Current server date. This is a calculated property based on the difference between the phone date and the date on the server. This property is available after the first successful operation list request. It might be nil if the server doesn't provide such a feature.
- `isLoadingOperations` - Indicates if the service is loading pending operations.
- `refreshOperations` - Async "fire and forget" request to refresh pending operations.
- `getOperations(completion: @escaping GetOperationsCompletion)` - Retrieves pending operations from the server.
    - `completion` - Called when the operation finishes. Always called on the main thread.
- `isPollingOperations` - If the app is periodically polling for the operations from the server.
- `pollingOptions` - Configuration of the polling feature
    - `pauseWhenOnBackground` - Polling will be paused when your app is in the background.
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
- `getHistory(authentication: PowerAuthAuthentication, completion: @escaping(Result<[WMTUserOperation],WMTError>) -> Void)` - Retrieves list of operations
  - `authentication` - PowerAuth authentication object for operation signing.
  - `completion` - Called when rejection request finishes. Always called on the main thread.
- `authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `qrOperation ` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authentication finishes. Always called on the main thread.
- `authorize(qrOperation: WMTQROperation, uriId: String, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void)` - Sign offline (QR) operation.
    - `qrOperation ` - Offline operation that can be retrieved via `WMTQROperationParser.parse` method.
    - `uriId` - Custom signature URI ID of the operation. Use the URI ID under which the operation was created on the server. Usually something like `/confirm/offline/operation`.
    - `authentication` - PowerAuth authentication object for operation signing.
    - `completion` - Called when authentication finishes. Always called on the main thread.

## WMTUserOperation

Operations objects retrieved through the `getOperations` API method are called "user operations".

Under this abstract name, you can imagine for example "Login operation", which is a request for signing in to the online account in a web browser on another device. **In general, it can be any operation that can be either approved or rejected by the user.**

Visually, the operation should be displayed as an info page with all the attributes (rows) of such an operation, where the user can decide if he wants to approve or reject it.

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
 
    /// Additional UI data to present
    ///
    /// Additional UI data such as Pre-Approval Screen or Post-Approval Screen should be presented.
    public let ui: WMTOperationUIData?   
    
    /// Proximity Check Data to be passed when OTP is handed to the app
    public var proximityCheck: WMTProximityCheck?
    
    /// Enum-like reason why the status has changed.
    ///
    /// Max 32 characters are expected. Possible values depend on the backend implementation and configuration.
    public let statusReason: String?
    
    /// Processing status of the operation
    public let status: Status
    
    /// Processing status of the operation
    public enum Status: String, Codable, CaseIterable {
        /// Operation was approved
        case approved = "APPROVED"
        /// Operation was rejected
        case rejected = "REJECTED"
        /// Operation is pending its resolution
        case pending = "PENDING"
        /// Operation was canceled
        case canceled = "CANCELED"
        /// Operation expired
        case expired = "EXPIRED"
        /// Operation failed
        case failed = "FAILED"
    }
}
```

Definition of `WMTOperationFormData`:

```swift
public class WMTOperationFormData {

    /// Title of the operation
    public let title: String

    /// Message for the user
    public let message: String
    
    /// Texts for the result of the operation
    ///
    /// This includes messages for different outcomes of the operation such as success, rejection, and failure.
    public let resultTexts: WMTResultTexts?

    /// Other attributes.
    ///
    /// Each attribute presents one line in the UI. Attributes are differentiated by `type` property
    /// and specific classes such as WMTOperationAttributeNote or WMTOperationAttributeAmount.
    public let attributes: [WMTOperationAttribute]
}
```

Definition of `WMTResultTexts`:

```swift
public class WMTResultTexts: Codable {
    
    /// Optional message to be displayed when the approval of the operation is successful.
    public let success: String?
    
    /// Optional message to be displayed when the operation approval fails.
    public let failure: String?
    
    /// Optional message to be displayed when the operation is rejected.
    public let reject: String?
}
```

Attributes types:  
- `AMOUNT` like "100.00 CZK"  
- `KEY_VALUE` any key-value pair  
- `NOTE` just like `KEY_VALUE`, emphasizing that the value is a note or message  
- `HEADING` single highlighted text, written in a larger font, used as a section heading  
- `PARTY_INFO` providing structured information about third-party data (for example known e-shop)  
- `AMOUNT_CONVERSION` provides data about Money conversion  
- `IMAGE` image row 
- `ALERT` alert view with title and message, used for displaying important information (warnings, errors or success) 
- `UNKNOWN` fallback option when an unknown attribute type is passed. Such an attribute only contains the label.

Definition of `WMTOperationUIData`:

```swift
open class WMTOperationUIData: Codable {
    /// Confirm and Reject buttons should be flipped both in position and style
    public let flipButtons: Bool?
    
    /// Block approval when on call (for example when on a phone or Skype call)
    public let blockApprovalOnCall: Bool?
    
    /// UI for multiple pre-approval screens
    public let preApprovalScreens: [WMTPreApprovalScreen]?
    
    /// UI for post-approval operation screen
    ///
    /// Type of PostApprovalScrren is presented with different classes (Starting with `WMTPostApprovalScreen*`)
    public let postApprovalScreen: WMTPostApprovalScreen?
}
```

#### PreApprovalScreens:

Pre-approval screens define additional UI that can be displayed before the user decides to approve or reject an operation. They allow to display structured instructions, warnings, or interactive elements to the user.

Types:

- `WARNING`
- `INFO`
- `QR_SCAN` this type indicates that the `WMTProximityCheck` must be used
- `UNKNOWN` 

A pre-approval screen can contain the following building blocks:

- Heading and message – textual content displayed at the top of the screen.
- Optional metadata
  - id - unique identifier
  - backButton - show navigation back button
  - image - in-app asset identifier
- Elements – structured items that form the main content of the screen:
  - List item – text with optional icon with style (INFO, WARNING, DANGER).
  - Alert – highlighted box with style (INFO, WARNING, DANGER).
  - Button – action element with LINK, MAIL, or PHONE, plus optional actionSettings string describing an additional behavior (e.g. "REJECT").
- Controls – configuration of approve/decline actions:
  - Decline – BACK or REJECT, with optional text. 
  - Approve – SLIDER or BUTTON, with optional text and optional countdown (counter). 
  - Layout options – axis (HORIZONTAL or VERTICAL) and flip (swap order of controls).

#### PostApprovalScreen:
`WMTPostApprovalScreen*` classes commonly contain `heading` and `message` and different payload data

Types:

- `REVIEW` provides an array of operations attributes with data: type, id, label, and note
- `REDIRECT` providing text for button, countdown, and redirection URL
- `GENERIC` may contain any object

Definition of `WMTProximityCheck`:

```swift
public class WMTProximityCheck: Codable {
    /// The actual Time-based one-time password
    public let totp: String
    /// Type of the Proximity check
    public let type: WMTProximityCheckType
    /// Timestamp when the operation was scanned (QR Code) or delivered to the device (Deeplink)
    public let timestampReceived: Date
}
```

WMTProximityCheckType types:

- `qrCode` TOTP was scanned from the QR code
- `deeplink` TOTP was delivered to the app via Deeplink


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
Task {
    do {
        let ops = try await opsService.getOperations()
        // unbox operations into the [CustomUserOperation]
        let unboxed = ops.map { $0 as! CustomUserOperation }
    } catch {
        // do something with the error
    }
}
```

## Creating a Custom Operation

In some specific scenarios, you might need to approve or reject an operation that you received through a different channel than `getOperations`. In such cases, you can implement the `WMTOperation` protocol in your custom class and then feed created objects to both `authorize` and `reject` methods.

<!-- begin box success -->
You can use the concrete convenient class `WMTLocalOperation`, which implements the `WMTOperation` protocol.
<!-- end -->

Definition of the `WMTOperation`:

```swift
public protocol WMTOperation {

    /// Operation identifier
    var id: String { get }

    /// Data for signing
    var data: String { get }
    
    /// Additional information with proximity check data
    var proximityCheck: WMTProximityCheck? { get }
}
```

### Utilizing the Proximity Check
When creating custom operations, you can now include proximity check data by conforming to the updated WMTOperation protocol. This enables you to enhance the security of your operations by considering proximity information during the authorization process.

To maintain backward compatibility, a public extension has been added to the WMTOperation protocol. If your existing codebase does not require the use of the proximity check feature, the extension ensures seamless integration:

```swift
public extension WMTOperation {
    var proximityCheck: WMTProximityCheck? { nil }
}
```

## WMTProximityCheck

Two-Factor Authentication (2FA) using Time-Based One-Time Passwords (TOTP) in the Operations Service is facilitated through the use of WMTProximityCheck. This allows secure approval of operations through QR code scanning or deeplink handling.

- QR Code Flow:

When the `WMTUserOperation` contains a `WMTPreApprovalScreen.qr`, the app should open the camera to scan the QR code before confirming the operation. Use the camera to scan the QR code containing the necessary data payload for the operation.

- Deeplink Flow:

When the app is launched via a deeplink, preserve the data from the deeplink and extract the relevant data. When operations are loaded compare the operation ID from the deeplink data to the operations within the app to find a match.

- Assign TOTP and Type to the Operation
Once the QR code is scanned or a match from the deeplink is found, create a `WMTProximityCheck` with:
    - `totp`: The actual Time-Based One-Time Password.
    - `type`: Set to `WMTProximityCheckType.qrCode` or `WMTProximityCheckType.deeplink`.
    - `timestampReceived`: The timestamp when the QR code was scanned (by default, it is created as the current timestamp).

- Authorizing the WMTProximityCheck
When authorized, the SDK will by default add `timestampSent` to the `WMTProximityCheck` object. This timestamp indicates when the operation was signed.

### WMTPACUtils
- For convenience, a utility class for parsing and extracting data from QR codes and deeplinks used in the PAC (Proximity Anti-fraud Check), is provided.

```swift
/// Data which is returned from parsing PAC code
public struct WMTPACData: Decodable {
	        
	/// The ID of the operation associated with the PAC
	public let operationId: String
	    
	/// Time-based one-time password used for Proximity antifraud check
	public let totp: String?
}
```

- two methods are provided:
    - `parseDeeplink(url: URL) -> WMTPACData?` - URI is expected to be in the format `scheme://code=$JWT` or `scheme://operation?oid=5b753d0d-d59a-49b7-bec4-eae258566dbb&potp=12345678`
    - `parseQRCode(code: String) -> WMTPACData?` - code is to be expected in the same format as deeplink formats or as a plain JWT
    - mentioned JWT should be in the format `{"type":"JWT", "alg":"none"}.{"oid":"5b753d0d-d59a-49b7-bec4-eae258566dbb", "potp":"12345678"} `
  
- Accepted formats:
  - notice that the totp key in JWT and query shall be `potp`!
         
## Error handling

Every error produced by the Operations Service is of a `WMTError` type. For more information see detailed [error handling documentation](Error-Handling.md).
