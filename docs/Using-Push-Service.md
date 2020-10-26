# Using Push Service

<!-- begin TOC -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Push Service API Reference](#push-service-api-reference)
- [Registering to WMT Push Notifications](#registering-to-wmt-push-notifications)
- [Receiving WMT Push Notifications](#receiving-wmt-push-notifications)
- [Error handling](#error-handling)
<!-- end -->

## Introduction

Push Service is responsible for registering the device for the push notifications about the Operations that are tied to the current PowerAuth activation.

> __Note:__ Before using Push Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, service will return an error

Push Service communicates with [Mobile Push Registration API](https://github.com/wultra/powerauth-webflow/blob/develop/docs/Mobile-Push-Registration-API.md).

## Creating an Instance

To create an instance of the push service, use the following snippet:

```swift
import WultraMobileTokenSDK

let opsConfig = WMTConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/push/api/")!,
    sslValidation: .default
)
let pushService = powerAuth.createWMTPush(config: config)
```

`sslValidation` property is used when validating HTTPS requests. Following strategies can be used.  

- `WMTSSLValidationStrategy.default` 
- `WMTSSLValidationStrategy.noValidation`
- `WMTSSLValidationStrategy.sslPinning` 

## Push Service API Reference

All available methods of the `WMTPush` API are:

- `pushNotificationsRegisteredOnServer` - If there was already made an successful request.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void)` - Registers push token on the backend.
    - `token` - token data retrieved from APNS.
    - `completionHandler` - Called when request finishes. Always called on the main thread.

## Registering to WMT Push Notifications

To register your app to push notifications regarding the operations, you can simply call the `registerDeviceTokenForPushNotifications` method:

```swift
// UIApplicationDelegate method
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    pushService.registerDeviceTokenForPushNotifications(token: deviceToken) { success, error in
        guard success else {
            // push registration failed
            return
        }
    }
}
```

_To make the above method called, you need to register the app to receive push notifications in the first place. For more information visit [official documentation](https://developer.apple.com/documentation/usernotifications/handling_notifications_and_notification-related_actions)._

## Receiving WMT Push Notifications

To process the raw notification obtained from Apple Push Notification service (APNs), you can use `WMTPushParser` helper class that will parse the notification into a `WMTPushMessage` result.

The `WMTPushMessage` can be following values

- `operationCreated` - a new operation was triggered with the following parameters
  -  `id` of the operation
  -  `name` of the operation
  -  `content` _(optional)_ of the message presented to the user.
  -  `originalData` - data on which was the push message constructed
- `operationFinished` - an operation was finished, successfully or non-successfully with following parameters
  -  `id` of the operation
  -  `name` of the operation
  -  `result` of the operation (for example that the operation was canceled by the user).
  -  `originalData` - data on which was the push message constructed


_Example push notification processing:_

```swift
// MARK: - UNUserNotificationCenterDelegate
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if let wmtnf = WMTPushParser.parseNotification(notification) {
        // process the mtoken notification and react to it in the UI
    }  else {
       // process all the other notification types using your own logic
    }
}
```

## Error handling

Every error produced by the Push Service is of a `WMTError` type. For more information see detailed [error handling documentation](Error-Handling.md).
