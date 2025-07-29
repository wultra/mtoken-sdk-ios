# Migration from 1.12.x to 2.0.x

This guide provides instructions for migrating from Wultra Mobile Token SDK for iOS version `1.12.x` to version `2.0.x`.

Version `2.0.x` introduces a significant simplification of the SDK’s design and usage.

---

### Added Functionality
**Preferred Instantiation Method**  
   The `WultraMobileToken` class is now the recommended way to instantiate the SDK.
   `PowerAuthSDK` extension method is provided for this purpose.
   
```kotlin
func createWultraTokenMobile(powerAuth: PowerAuthSDK) {
    do {
        let wmt = powerAuth.createWultraMobileToken()
    
        let operationsService = wmt.operations
        let pushService = wmt.inbox
        let inboxService = wmt.push
    
    } catch InitError.invalidBaseURL(let url) {
        // PowerAuth baseUrl is not valid
    }
}
```

### Removed Functionality

1. **Removed protocols**

The protocols `WMTOperations`, `WMTInbox`, and `WMTPush` have been removed and replaced by concrete class implementations.

2. **Removed Extension Methods**  

The following extension methods of `PowerAuthSDK` and `WPNNetworkingService` have been removed:
      -  `createWMTOperations()`
      -  `createWMTInbox()`
      -  `createWMTPush`

Services should now be instantiated using the recommended `WultraMobileToken` approach. For advanced service configuration, refer to the links below.


   - [Using Operations Service: Creating an Instance](./Using-Operations-Service.md#creating-an-instance)
   - [Using Push Service: Creating an Instance](./Using-Push-Service.md#creating-an-instance)
   - [Using Inbox Service: Creating an Instance](./Using-Inbox-Service.md#creating-an-instance)

3. **Removed Polling Options**  

The `WMTOperationsPollingOptions` class has been removed for simplification. If you require features such as polling pauses, this functionality is now outside the scope of the SDK.

4. **`WMTOperations` no longer uses generics but only `WMTUserOperation`**

5. **Subspecs removal**

`Operations`, `Push`, and `Inbox` subspecs are no longer available for Cocoapods integration.


## Implement status in WMTUserOperation

### Added Functionality

The following status property was added to the `WMTUserOperations`:

```swift
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
```

The `WMTUserOperation.status` now represents the status of an operation, making the `WMTOperationHistoryEntry` redundant. As a result, `WMTOperationHistoryEntry` has been removed. In all instances where `WMTOperationHistoryEntry` was previously used, `WMTUserOperation` is used instead.

<!-- begin box info -->
ℹ️ **Note:** Starting with version `2.0.1` (and also in `2.1.1`, `2.2.1`), the `status` property has become **nullable** (`Status?`) to align with backend behavior, where this field may be omitted.
<!-- end -->

### Replaced at

In the `getHistory` method of `WMTOperations`, `WMTOperationHistoryEntry` has been replaced by `WMTUserOperation` for retrieving user operation history.

```swift
    /// Retrieves the history of user operations with its current status.
    /// - Parameters:
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getHistory(authentication: PowerAuthAuthentication, completion: @escaping(Result<[WMTUserOperation], WMTError>) -> Void) -> Operation?
```
