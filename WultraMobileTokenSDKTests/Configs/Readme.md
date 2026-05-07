To run `WultraMobileTokenSDKTests` scheme you have to create a `config.json` file in this folder first with all the necessary information.

The `sdkConfig` is fetched from the cloud server at test runtime and is **not** part of this file.

_Example config:_

```json
{
    "cloudServerUrl"        : "https://url-to-my-cloud.com/powerauth-cloud",
    "cloudServerLogin"      : "admin",
    "cloudServerPassword"   : "admin",
    "cloudApplicationId"    : "dev",
    "enrollmentServerUrl"   : "https://url-to-my-cloud.com/enrollment-server"
}
```

OIDC tests additionally accept optional `oidcProviderId` and `oidcProviderIdPkce` keys.
