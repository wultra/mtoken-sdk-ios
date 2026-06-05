# Wultra Mobile Token SDK for iOS

With Wultra Mobile Token (WMT) SDK, you can integrate an out-of-band operation approval into an existing mobile app, instead of using a standalone mobile token application. WMT is built on top of [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk). It communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

To understand the Wultra Mobile Token SDK purpose on a business level better, you can visit our own [Mobile Token application](https://www.wultra.com/mobile-token). We use Wultra Mobile Token SDK in our mobile token application as well.

WMT SDK library does precisely this:

- Retrieves, approves, or rejects operations pending approval for a given user.
- Registers an existing PowerAuth activation to receive push notifications.
- Manages user's inbox messages.
- Handles OpenID Connect (OIDC) authentication flows.

Remarks:

- This library does not contain any UI.
- We also provide an [Android version of this library](https://github.com/wultra/mtoken-sdk-android).

<!-- begin remove -->
## Integration Tutorials
- [SDK Integration](SDK-Integration.md)
- [Example Usage](Example-Usage.md)
- [Using Operations Service](Using-Operations-Service.md)
- [Using Push Service](Using-Push-Service.md)
- [Using Inbox Service](Using-Inbox-Service.md)
- [Using OIDC Service](Using-OIDC-Service.md)
- [Operation Expiration Handling](Operation-Expiration.md)
- [Error Handling](Error-Handling.md)
- [Language Configuration](Language-Configuration.md)
- [Logging](Logging.md)
- [Changelog](Changelog.md)
- [Migration Guides](Migration-Guides.md)
<!-- end -->
