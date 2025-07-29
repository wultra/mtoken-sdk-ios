# Language Configuration

### Usage

You can use `WultraMobileToken.setAcceptLanguage` set to the user's preferred language for all WMT services. 

If you're creating services manually (e.g., `WMTOperations`), you can set the `acceptLanguage` property directly.

### Format

The default value is always `en`. With other languages, we use values compliant with standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

<!-- begin box info -->
The language properties are just a wrap-around of the underlying networking language configuration described in [our networking library documentation](https://github.com/wultra/networking-apple).
<!-- end -->

<!-- begin box warning -->
Note: Content language capabilities are limited by the implementation of the server - it must support the provided language.
<!-- end -->