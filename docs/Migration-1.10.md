# Migration from 1.9.x to 1.10.x

This guide contains instructions for migration from Wultra Mobile Token SDK for iOS version `1.9.x` to version `1.10.x`.

## Current Server Date

### Removed Functionality

The following calculated property was removed from the `WMTOperations` protocol:

```swift
var currentServerDate: Date? { get }
```

The `currentServerDate` is a calculated property based on the difference between the phone's date and the date on the server. However, it had limitations and could be incorrect under certain circumstances, such as when the user decided to change the system time during the runtime of the application.

### Replace with

The new time synchronization directly from `PowerAuthSDK.timeSynchronizationService` is more precise and reliable. 

Here is the updated test method for reference:

```swift
/// `currentServerDate` was removed from WMTOperations in favor of more precise powerAuth timeService
func testCurrentServerDate() {
    var synchronizedServerDate: Date? = nil
    let timeService = pa.timeSynchronizationService
    if timeService.isTimeSynchronized {
        synchronizedServerDate = Date(timeIntervalSince1970: timeService.currentTime())
    }
        
    XCTAssertNotNil(synchronizedServerDate)
}
```
