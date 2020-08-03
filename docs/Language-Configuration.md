# Language Configuration

Before using any methods from this SDK that call the backend, a proper language should be set. A properly translated content is served based on this configuration. The property that stores language settings is not persisted. You need to set `acceptLanguage` every time that the application boots.

### Usage

Both `WMTOperations` and `WMTPush` contain an `acceptLanguage` property that should be set to the user's preferred language.

### Format

The default value is always `en`. With other languages, we use values compliant with standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

_Note: Content language capabilities are limited by the implementation of the server - it must support the provided language._
