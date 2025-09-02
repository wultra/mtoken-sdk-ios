# Migration from 2.1.x to 2.2.x

This guide provides instructions for migrating from Wultra Mobile Token SDK for iOS version `2.1.x` to version `2.2.x`.

---

## Changes in `WMTPush` API

Method `registerDeviceTokenForPushNotifications` has been deprecated in favor of the new `register(to:completion:)` method. 

The new method adds: 
- support for __Firebase Cloud Messages__ (FCM) 
- specification of the environment (release or development) for __Apple Push Notification service__ (APNs).

----

<!-- begin box warning -->
If your server is running an older version than `1.10.x`, use the `registerDeviceTokenForPushNotifications(token:completion:)` deprecated method instead to stay compatible.
<!-- end -->
