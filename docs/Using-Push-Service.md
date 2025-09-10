# Using Push Service

<!-- begin remove -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Push Service API Reference](#push-service-api-reference)
- [Registering to WMT Push Notifications](#registering-to-wmt-push-notifications)
- [Receiving WMT Push Notifications](#receiving-wmt-push-notifications)
- [Error handling](#error-handling)

## Introduction
<!-- end -->

Push Service is responsible for registering the device for the push notifications about operations that are tied to the current PowerAuth activation.

<!-- begin box warning -->
Note: Before using Push Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, the service will return an error
<!-- end -->

Push Service communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Creating an Instance

The preferred way of instantiating Push Service is via `WultraMobileToken` class.
See: [Example Usage](./Example-Usage)


### Customized initialization

If you need to create a more customized instance, such as when your Push Service uses a different enrollment server URL than other services in the SDK, you can use an initializer. Simply define the networking configuration and provide the PowerAuthSDK instance.

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
    serviceName: "PushService",
    acceptLanguage: "en"
)

let opsService = WMTPush(networking: networkingService)
```

## Push Service API Reference

All available methods of the `WMTPush` API are:

- `pushNotificationsRegisteredOnServer` - If there was already made a successful request.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `register(to: WMTPushPlatform, completionHandler: completion: @escaping (Result<Void, WMTError>) -> Void)` - Registers push token on the backend.
    - `to` - Platform and data needed (APNS or FCM + push token)
    - `completionHandler` - Called when the request finishes. Always called on the main thread.

## Registering to WMT Push Notifications

### Using APNS (Apple Push Notification Service)

<!-- begin box warning -->
If your server is running an older version than `1.10.x`, use the `registerDeviceTokenForPushNotifications(token:completion:)` deprecated method instead to stay compatible.
<!-- end -->

To register your app to push notifications regarding the operations, you can simply call the `register` method with `.apns` platform parameter:

```swift
// UIApplicationDelegate method
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    pushService.register(to: .apns(token: deviceToken)) { result in
        if case .failure(let error) = result {
            // registration failed
        }
    }
}
```

<!-- begin box warning -->
The above method will get called only if you registered the app to receive push notifications. For more information, visit the [official apple documentation](https://developer.apple.com/documentation/usernotifications/handling_notifications_and_notification-related_actions).
<!-- end -->

### Using FCM (Firebase Cloud Messaging)

To register your app to push notifications regarding the operations, you can simply call the `register` method with `.fcm` platform parameter:

```swift
func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken else {
        // token not received
        return
    }
    pushService.register(to: .fcm(token: fcmToken)) { result in
        if case .failure(let error) = result {
            // registration failed
        }
    }
}
```

<!-- begin box warning -->
To properly configure FCM for iOS, follow [official google documentation](https://firebase.google.com/docs/cloud-messaging/ios/client).
<!-- end -->

## Receiving WMT Push Notifications

To process the raw notification obtained from the Apple Push Notification Service (APNS), you can use `WMTPushParser` helper class that will parse the notification into a `WMTPushMessage` result.

The `WMTPushMessage` can be following values

- `operationCreated` - a new operation was triggered with the following parameters
  -  `id` of the operation
  -  `name` of the operation
  -  `content` _(optional)_ of the message presented to the user.
  -  `originalData` - data on which was the push message constructed
- `operationFinished` - an operation was finished, successfully or non-successfully with the following parameters
  -  `id` of the operation
  -  `name` of the operation
  -  `result` of the operation (for example that the operation was canceled by the user).
  -  `originalData` - data on which was the push message constructed
- `inboxMessageReceived` - a new inbox message was triggered.
  -  `id` of the message
  -  `originalData` - data on which was the push message constructed

Example push notification processing:

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
