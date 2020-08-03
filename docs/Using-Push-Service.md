# Using Push Service

<!-- begin TOC -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Registering to Push Notifications](#registering-to-push-notifications)
- [Push Service API Reference](#push-service-api-reference)
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

## Registering to Push Notifications

To register an app to push notifications, you can simply call the register method:

```swift
// AppDelegate method
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    pushService.registerDeviceTokenForPushNotifications(token: deviceToken) { success, error in
        guard success else {
            // push registration failed
            return
        }
    }
}
```

## Push Service API Reference

All available methods of the `WMTPush` API are:

- `pushNotificationsRegisteredOnServer` - If there was already made an successful request.
- `config` - Config object, that was used for initialization.
- `acceptLanguage` - Language settings, that will be sent along with each request.
- `registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void)` - Registers push token on the backend.
    - `token` - token data retrieved from APNS.
    - `completionHandler` - Called when request finishes.