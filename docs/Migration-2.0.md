# Migration from 1.12.x to 2.0.x

This guide provides instructions for migrating from Wultra Mobile Token SDK for iOS version `1.12.x` to version `2.0.x`.

Version `2.0.x` introduces a significant simplification of the SDK’s design and usage.

---

### Added Functionality
**Preferred Instantiation Method**  
   The `WultraMobileToken` class is now the recommended way to instantiate the SDK.
   PowerAuthSDK extension method is provided for this purpose.
   
```kotlin
func createWultraTokenMobile(powerAuth: PowerAuthSDK) {
    do {
        let wmt = powerAuth.createWultraMobileToken()
    
        let operationsService = wmt.operations
        let pushService = wmt.inbox
        let inboxService = wmt.push
    
    } catch IntiError.invalidBaseURL(let url) {
        // PowerAuth baseUrl is not valid
    }
}
```

### Removed Functionality

1. **Removed Extension Methods**  
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
