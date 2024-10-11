# Migration from 1.11.x to 1.12.x

This guide contains instructions for migration from Wultra Mobile Token SDK for iOS version `1.11.x` to version `1.12.x`.

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
