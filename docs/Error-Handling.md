# Error Handling

Every error produced by this library is of a `WMTError` type. This error contains the following information:

- `reason` - Specific reason, why the error happened.
- `nestedError` - Original exception/error (if available) that caused this error.
- `httpStatusCode` - If the error is networking error, this property will provide HTTP status code of the error.
- `httpUrlResponse` - If the error is networking errror, this will hold original HTTP response that was recieved from the backend.
- `restApiError` - If the error is a "well-known" API error, it will be filled here.
- `networkIsNotReachable` - Convenience property, informs about a state where the network is not available (based on the error type).
- `networkConnectionIsNotTrusted` - Convenience property, informs about a TLS error.
- `powerAuthErrorResponse` - If the error was caused by the PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - If the error was caused by the PowerAuth error, the error code of the original error will be available here.

## Known API Error codes

| Error Code | Description |
|---|---|
|`authenticationFailure`|General authentication failure (wrong password, wrong activation state, etc...)|
|`invalidRequest`|Invalid request sent - missing request object in the request|
|`invalidActivation`|Activation is not valid (it is different from configured activation)|
|`pushRegistrationFailed`|Error code for a situation when registration to push notification fails|
|`operationAlreadyFinished`|Operation is already finished|
|`operationAlreadyFailed`|Operation is already failed|
|`operationAlreadyCancelled`|Operation is canceled|
|`operationExpired`|Operation is expired|