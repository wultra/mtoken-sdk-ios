# Operation Expiration Handling

Every operation should have an expiration time. An expired operation cannot be confirmed nor rejected - the server will return an error with the appropriate error (see [Operation errors](Error-Handling.md#operation-errors)).

## Retrieving Expiration Time

### WMTUserOperation
The `WMTUserOperation` provided by the `WMTOperations` service has its expiration time inside the `operationExpires` property.

### Custom Operation
If you're creating your own custom operation by implementing the `WMTOperation` protocol, you need to provide the expiration time by yourself. The expiration time is optional because it's not part of the operation signature.

## Handling via Push Notifications

If the device is [registered to receive push notifications](Using-Push-Service.md), it will receive an [`operationFinished`](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Push/WMTPushParser.swift#L77#docucheck-keep-link) notification with the [`timeout`](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Push/WMTPushParser.swift#L86#docucheck-keep-link) result when the operation expires.

Operation list should be refreshed on such notification.

Please be aware that push notifications are not guaranteed to be received. There are several scenarios where push notification delivery will fail, such as:

- user didn't grant notification permissions to your app
- network error occurred
- notification token has expired and is waiting for renewal
- ... other situations not under the developer's control

## Local Handling

Since push notifications are not guaranteed to be delivered, you should implement a mechanism that will refresh the list to validate if it was expired on the server too.

Server and client device time could differ! You should never remove the operation just locally, but refresh the operation list instead.

### WMTOperationExpirationWatcher

Utility class that will observe operations and informs you when it expired.

#### Sample Implementation

```swift
// Sample implementation of a class that's using the WMTOperationExpirationWatcher
class MyOperationsService: WMTOperationsDelegate, WMTOperationExpirationWatcherDelegate {

    private let ops: WMTOperations
    private let expirationWatcher = WMTOperationExpirationWatcher()

    init(ops: WMTOperations) {
        self.ops = ops
        // set delegates to observer operation and expiration results
        self.ops.delegate = self
        self.expirationWatcher.delegate = self
    }

    func refreshOperations() {
        ops.refreshOperations()
    }

    func operationsLoading(loading: Bool) {
        // process operations loading state change
        // not needed for the sample
    }

    func operationsFailed(error: WMTError) {
        // process operations loading state change
        // not needed for the sample
    }

    func operationsChanged(operations: [UserOperation], removed: [UserOperation], added: [UserOperation]) {
        // simplified but working example how operations can be observed for expiration
        expirationWatcher.removeAll()
        expirationWatcher.add(operations)

        // process operations
        // ...
    }

    // MARK: - WMTOperationExpirationWatcherDelegate

    func operationsExpired(_ expiredOperations: [WMTExpirableOperation]) {
        // some operation expired, refresh the list
        refreshOperations()
        // this behavior could be improved for example with
        // checking if the expired operations is currently displayed etc..
    }
}
```
