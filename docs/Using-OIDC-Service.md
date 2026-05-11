# OIDC and PowerAuth Integration

- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Retrieving Configuration](#retrieving-configuration)
- [Preparing OIDC Authorization Data](#preparing-oidc-authorization-data)
- [Registering URL Schemes for Deeplinks](#registering-url-schemes-for-deeplinks)
- [Open authorize URL in a web browser](#open-authorize-url-in-a-web-browser)
- [Processing a Web Callback and initializing PowerAuth activation flow](#processing-a-web-callback-and-initializing-powerAuth-activation-flow)
- [WMTOIDCUtils](#wmtoidcutils)

## Introduction

The OIDC and PowerAuth integration enables secure user authentication and the preparation of necessary attributes to initiate a PowerAuth activation. This integration provides tools for managing OpenID Connect (OIDC) flows, including preparing for OIDC activation, processing web callbacks, and handling PKCE codes and authorization URLs.

OIDC is commonly used for scenarios like secure user login, authorization to access resources, or linking third-party accounts.

<!-- begin box warning -->
Note: Before using the OIDC and PowerAuth integration, you need to have a `PowerAuthSDK` object available.
<!-- end -->

The integration communicates with the [OpenID Connect Standard](https://openid.net/connect/) and enhances the process with secure PKCE (Proof Key for Code Exchange) and state validation to ensure the integrity of the OIDC flow.

---

## Creating an Instance

The preferred way of instantiating Operations Service is via the `WultraMobileToken` class.
See: [Example Usage](./Example-Usage)

### Customized initialization

If you need to create a more customized instance, you can do so as follows.

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
    serviceName: "OIDCService",
    acceptLanguage: "en"
)

let oidcService = WMTOIDC(networking: networkingService)
```

## Retrieving Configuration

Note: The async/throws `getConfig(providerId:)` method shown here also has a callback-based counterpart (`completion: @escaping (Result<WMTOIDCConfig, WMTError>) -> Void`) if you prefer the closure style.

The `getConfig` method retrieves the OIDC provider configuration based on a predefined `providerId`, returning a `WMTOIDCConfig` object with essential details about the provider, client, and PKCE settings.

### WMTOIDCConfig

The `WMTOIDCConfig` structure contains essential OIDC configuration values for authentication.

| Property        | Type    | Description                                                                                     |
|-----------------|---------|------------------------------------------------------------------------------|
| `providerId`    | `String`| The unique identifier for the OIDC provider.                                                   |
| `clientId`      | `String`| The OAuth 2.0 client ID used to form the URL for the authorization request.                     |
| `scopes`        | `String`| A space-delimited list of OAuth 2.0 scopes for the authorization request.                       |
| `authorizeUri`  | `String`| The OAuth 2.0 authorization URI where the user is redirected for authentication.                |
| `redirectUri`   | `String`| The OAuth 2.0 redirect URI where the server sends responses after authentication.               |
| `pkceEnabled`   | `Bool`  | Indicates whether PKCE (Proof Key for Code Exchange) should be used in the authentication flow. |


##### Example:

```swift
Task {
    do {
        let config = try await oidcService.getConfig(providerId: "example_provider")
        // OIDC configuration
    } catch {
        // show error
    }
}
```


## Preparing OIDC Authorization Data

The `prepareAuthorizationData` method generates the necessary data for initiating the OIDC authorization process from `WMTOIDCConfig`. `WMTOIDCConfig` can be obtained by calling `getConfig(providerId)` or instantiated directly. 


##### WMTOIDCAuthorizationRequest

Encapsulates the data required to initiate the OIDC authorization flow and also other properties for PowerAuth Activation flow.

| Property         | Type      | Description                                             |
|------------------|-----------|---------------------------------------------------------|
| `authorizeUrl`   | `URL`     | URL to redirect the user for OIDC authentication.       |
| `providerId`     | `String`  | Identifier for the OIDC provider configuration.         |
| `nonce`          | `String`  | Random value to prevent replay attacks.                 |
| `state`          | `String`  | Random value to maintain state between request/callback.|
| `codeVerifier`   | `String?` | PKCE code verifier, if applicable.                      |



####Example
```swift
let result = oidcService.prepareAuthorizationData(config: oidcConfig)
switch result {
case .success(let oidcAuthRequest):
    // Use oidcAuthRequest.authorizeUri to open the browser (ASWebAuthenticationSession)
case .failure(let error):
    // 
}
```

## Registering URL Schemes for Deeplinks

Before you can handle OIDC callbacks in your iOS app, you must register the appropriate URL schemes in your app's `Info.plist` file. This is essential for enabling your app to receive deeplink callbacks from the OIDC authorization flow.

### Configuring Info.plist

Add the following configuration to your app's `Info.plist` file to register URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp.oidc</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### URL Scheme Configuration Details

| Property | Description | Example |
|----------|-------------|---------|
| `CFBundleURLName` | A unique identifier for the URL type | `com.yourcompany.yourapp.oidc` |
| `CFBundleURLSchemes` | Array of URL schemes your app handles | `["yourapp"]` |

### Choosing the Right URL Scheme

The URL scheme you register should match either:

1. **The scheme from your OIDC configuration's `redirectUri`**: If your OIDC provider is configured with a redirect URI like `yourapp://oidc/callback`, register `yourapp` as the scheme.

2. **A custom scheme for your app**: Use a unique scheme that identifies your app, such as `com.yourcompany.yourapp` or a shorter variant like `yourapp`.

### Example Configuration

If your OIDC provider is configured with:
- Redirect URI: `mybanking://oidc/auth/callback`

Then your `Info.plist` should include:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.mycompany.mybanking.oidc</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mybanking</string>
        </array>
    </dict>
</array>
```

<!-- begin box info -->
**Note**: The URL scheme registration in `Info.plist` is mandatory for OIDC deeplink handling to work properly. Without this configuration, your app will not be able to receive authorization callbacks from the OIDC provider.
<!-- end -->

### Handling URL Callbacks in Your App

Once you've registered the URL schemes, you'll also need to handle the incoming URLs in your app. This is typically done in your `AppDelegate` or `SceneDelegate`:

```swift
// In AppDelegate.swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Handle the OIDC callback URL here
    // You can pass this URL to WMTOIDCUtils.processWebCallback()
    handleOIDCCallback(url: url)
    return true
}

// In SceneDelegate.swift (iOS 13+)
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
        // Handle the OIDC callback URL here
        handleOIDCCallback(url: url)
    }
}
```

## Open authorize URL in a web browser


To start the OIDC flow, you must open the authorization URL in a web browser. The recommended approach on iOS is to use `ASWebAuthenticationSession` for a seamless and secure user experience. 

`ASWebAuthenticationSession` requires a `callbackURLScheme` parameter, which should match the URL scheme you registered in your app's `Info.plist` (see [Registering URL Schemes for Deeplinks](#registering-url-schemes-for-deeplinks)). You can use either:
- The scheme from your `WMTOIDCConfig.redirectUri`
- The custom deeplink scheme defined in your `CFBundleURLSchemes`

Since the Wultra Mobile Token SDK does not include any UI logic, it is up to you to implement this functionality. Below is an example of how you can handle the flow:

### Example

```swift
func openWebBrowser(oidcAuthRequest: WMTOIDCAuthorizationRequest, completion: @escaping (Result<URL, Error>) -> Void) {
    // The callback scheme should match what you registered in Info.plist
    let callbackScheme = "yourapp" // This should match your CFBundleURLSchemes
    
    // Create an instance of ASWebAuthenticationSession
    let webAuthSession = ASWebAuthenticationSession(
        url: oidcAuthRequest.authorizationUrl,
        callbackURLScheme: callbackScheme,
    ) { callbackURL, error in
        if let callbackURL = callbackURL {
            // Successful authorization - this URL will have your registered scheme
            // e.g., "yourapp://oidc/callback?code=...&state=..."
            completion(.success(callbackURL))
        } else if let error = error {
            // Handle error (e.g., user canceled the authorization)
            completion(.failure(error))
        }
    }

    webAuthSession.presentationContextProvider = self
    webAuthSession.prefersEphemeralWebBrowserSession = true // Avoid shared cookies if needed
    webAuthSession.start()
}
```


## Processing a Web Callback and initializing PowerAuth activation flow

After the user completes the OIDC flow in the web browser, the returned URL can be processed to extract the necessary attributes. 
The `WMTOIDCUtils.processWebCallback` utility function extracts and validates the data needed to initiate PowerAuth activation.
Additionally, the `WMTOIDCAuthorizationRequest` object, which was used to initiate the OIDC flow, is required to provide essential properties (nonce, providerId, and codeVerifier) for the activation process.


##### WMTOIDCPowerAuthActivationAttributes

Represents the attributes required to initiate a PowerAuth activation after completing an OIDC flow.

| Property       | Type      | Description                                        |
|----------------|-----------|----------------------------------------------------|
| `providerId`   | `String`  | Identifier for the OIDC provider configuration.    |
| `code`         | `String`  | Authorization code received from the OIDC flow.    |
| `nonce`        | `String`  | Random value for ensuring integrity of the flow.   |
| `codeVerifier` | `String?` | PKCE code verifier, if applicable.                 |


### Initiating PowerAuth Activation with OIDC

The final step in the OIDC and PowerAuth integration is to use the **`createOIDCActivation`** method. This extension function on `PowerAuthSDK` initiates the activation process by calling the PowerAuth Standard RESTful API.


```swift
do {
    // Process the callback to extract activation attributes
    let activationAttributes = try WMTOIDCUtils.processWebCallback(
        from: callbackUrl, 
        with: oidcAuthorizationRequest // Pass the same data as used for the OIDC flow
    )

    // Initiate PowerAuth activation using the extracted attributes
    let activationTask = try powerAuthSDK.createOIDCActivation(
        attributes: activationAttributes,
        deviceName: "Petr's iPhone 7"
    ) { result in
        switch result {
        case .success(let activationResult):
            // Activation succeeded
            // now proceed with activation flow - pin, activation commit etc.
        case .failure(let error):
            print("Activation failed: \(error)")
        }
    }
} catch {
    print("Error initializing PowerAuth activation: \(error)")
}

```

## WMTOIDCUtils

#### PKCE

Provides methods for generating PKCE codes.

- **`createPKCE`**: Generates a code verifier and code challenge based on the length input (data length is in range from 32 to 96 octet sequence which is 43 - 128 Base64 URL safe characters).
                    

```swift
guard let pkceResult = try? WMTOIDCUtils.createPKCE(32) else {
    // Error during generating PKCE codes
}
```

#### Random String Generation

Provides a method to generate cryptographically secure random strings in Base64 URL-safe format, commonly used for nonces, states, and PKCE code verifiers.

- **`getRandomBase64UrlSafe`**: Generates a code verifier and code challenge based on the length input.

```swift
val nonce = WMTOIDCUtils.getRandomBase64UrlSafe(32)
```

#### URL

Provides methods for handling URIs.

- **`createAuthorizationUri`**: Constructs an authorization URI.

```swift
let urlResult = WMTOIDCUtils.createAuthorizationUrl(config: config, nonce: nonce, state: state, pkceCodes: pkceCodes)
switch urlResult {
case .success(let authorizationUrl):
    // Authorization URL to be opened in the browser
case .failure(let error):
    // creation of the URL failed
}
```

- **`processWebCallback`**: Processes a web callback and compares it with input authorization request data to extract activation attributes.

```swift
do {
    let activationAttributes = try WMTOIDCUtils.processWebCallback(from: deeplinkUrl, with: oidcAuth)
    // Activation can continue with extension function 
    powerAuthSdk.createOIDCActivation(
        attributes: activationAttributes,
        activationName: "Petr's iPhone 7") { activationResult in
            switch activationResult {
            case .success(let activation):
            case .failure(let error):
            }
        }
    )
} catch {
    // Activation attributes cannot be created
}

if (activationAttributes != null) {
    println("Activation attributes ready: $activationAttributes")
} else {
    println("Failed to process deeplink URI.")
}
```
