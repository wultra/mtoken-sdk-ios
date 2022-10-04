# Logging

For logging purposes, WMT uses `WMTLogger` class that prints to the console.

<!-- begin box info -->
Note that logging to the console is available only when the library is compiled in the `Debug` mode or with `WMT_ENABLE_LOGGING` Swift compile condition.
<!-- end -->

### Verbosity Level

You can limit the amount of logged information via `verboseLevel` property.

| Level | Description |
| --- | --- |
| `off` | Silences all messages. |
| `errors` | Only errors will be printed to the debug console. |
| `warnings` _(default)_ | Errors and warnings will be printed to the debug console. |
| `all` | All messages will be printed to the debug console. |

Example configuration:

```swift
import WultraMobileTokenSDK

WMTLogger.verboseLevel = .all
```