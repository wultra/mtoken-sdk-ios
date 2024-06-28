# Logging

You can set up logging for the library using the `WMTLogger` class.

### Verbosity Level

You can limit the amount of logged information via the `verboseLevel` property.

| Level                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| `off`                  | Silences all messages.                            |
| `errors`               | Only errors will be logged.                       |
| `warnings` _(default)_ | Errors and warnings will be logged.               |
| `info`                 | Error, warning and info messages will be logged.  |
| `all`                  | All messages will be logged.                      |

### Logger Delegate

In case you want to process logs on your own (for example log into a file or some cloud service), you can set `WMTLogger.delegate`.
