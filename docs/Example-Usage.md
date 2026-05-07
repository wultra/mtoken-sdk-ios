# Example Usage

This is an example of the most common use case of this SDK - fetching operations and approving them.

## SDK Integration

Follow the [SDK Integration](./SDK-Integration.md) tutorial for SDK installation.

## Example Code

Note: The async/throws methods shown here also have callback-based counterparts (`completion: @escaping (Result<…, WMTError>) -> Void`) if you prefer the closure style.

```swift
// PowerAuth instance needs to be configured and a user-activated instance.
// More about PowerAuth SDK can be found here: https://github.com/wultra/powerauth-mobile-sdk

import PowerAuth2
import WultraMobileTokenSDK

func exampleUsage(powerAuth: PowerAuthSDK) {
    do {
        let mtoken = try powerauth.createWultraMobileToken(acceptLanguage: "de") // create the WultraMobileToken instance and set "requested content" to german language (default is english - "en")

        Task {
            do {
                let ops = try await mtoken.operations.getOperations()
                // we expect at least 1 operation in the list for the example purposes
                let auth = PowerAuthAuthentication.possessionWithPassword(password: "1234") // simulate that user entered PIN 1234
                try await mtoken.operations.authorize(operation: ops.first!, with: auth)
                // handle successful authorization
            } catch {
                // operation fetch or authorization failed
            }
        }
    } catch {
        // PowerAuth baseUrl is not valid
    }
}

```

For more examples see [IntegrationTests](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDKTests/IntegrationTests.swift)

## Read Next

- [Using Operations Service](./Using-Operations-Service.md)
- [Using Push Service](./Using-Push-Service.md)
- [Using Inbox Service](./Using-Inbox-Service.md)
- [Using OIDC Service](./Using-OIDC-Service.md)
