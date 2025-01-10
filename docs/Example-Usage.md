# Example Usage

This is an example of the most common use case of this SDK - fetching operations and approving them.

## SDK Integration

Follow the [SDK Integration](./SDK-Integration.md) tutorial for SDK installation.

## Example Code

```swift
// PowerAuth instance needs to be configured and a user-activated instance.
// More about PowerAuth SDK can be found here: https://github.com/wultra/powerauth-mobile-sdk

func exampleUsage(powerAuth: PowerAuth) {
do {
    let mtoken = try powerauth.createWultraMobileToken(acceptLanguage: "de") // create the WultraMobileToken instance and set "requested content" to german language (default is english - "en")

    let operations = mtoken.operations.getOperations { result in   
        
        switch result {
        case .success(let ops):
            let auth = PowerAuthAuthentication.possessionWithPassword(password: "1234") // simulate that user entered PIN 1234
            mtoken.operations.authorize(operation: ops.first!, with: auth) { result in
                // handle success or failure of authorization
            }
        case .failure(let err):
            //operation failed
        }
    }     
} catch {
    // PowerAuth baseUrl is not valid
}

```

For more examples see [IntegrationTests](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDKTests/IntegrationTests.swift)

## Read Next

- [Using Operations](./Using-Operations.md)