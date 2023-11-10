# Error Handling

Every error produced by this library is of a `WMTError` type. This error contains the following information:

- `reason` - A specific reason, why the error happened. For more information see [WMTErrorReason chapter](#wmterrorreason).
- `nestedError` - Original exception/error (if available) that caused this error.
- `httpStatusCode` - If the error is networking error, this property will provide HTTP status code of the error.
- `httpUrlResponse` - If the error is networking errror, this will hold original HTTP response that was recieved from the backend.
- `restApiError` - If the error is a "well-known" API error, it will be filled here. For more information see [Known REST API Error codes](#known-rest-api-error-codes).
- `networkIsNotReachable` - Convenience property, informs about a state where the network is not available (based on the error type).
- `networkConnectionIsNotTrusted` - Convenience property, informs about a TLS error.
- `powerAuthErrorResponse` - If the error was caused by the PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - If the error was caused by the PowerAuth error, the error code of the original error will be available here.

## Known REST API Error codes

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
|`operationFailed`|Default operation action failure|

## WMTErrorReason

Each `WMTError` has a `reason` property why the error was created. Such reason can be useful when you're creating for example a general error handling or reporting, or when you're debugging the code.

### General errors  

| Option Name | Description |
|---|---|
|`unknown`|Unknown fallback reason|
|`missingActivation`|PowerAuth instance is missing an activation.|

### Network errors

| Option Name | Description |
|---|---|
|`network_unknown`|When unknown (usually logic error) happened during networking.|
|`network_generic`|When generic networking error happened.|
|`network_errorStatusCode`|HTTP response code was different than 200 (success).`
|`network_invalidResponseObject`|An unexpected response from the server.|
|`network_invalidRequestObject`|Request is not valid. Such an object is not sent to the server.|
|`network_signError`|When the signing of the request failed.|
|`network_timeOut`|Request timed out|
|`network_noInternetConnection`|Not connected to the internet.|
|`network_badServerResponse`|Bad (malformed) HTTP server response. Probably an unexpected HTTP server error.|
|`network_sslError`|SSL error. For detailed information, see the attached error object when available.|

### Operation errors

| Option Name | Description |
|---|---|
|`operations_invalidActivation`|Request needs valid powerauth activation.|
|`operations_alreadyFailed`|Operation is already in a failed state.|
|`operations_alreadyFinished`|Operation is already in a finished state.|
|`operations_alreadyCanceled`|Operation is already in a canceled state.|
|`operations_alreadyRejected`|Operation expired.|
|`operations_authExpired`|Operation has expired when trying to approve the operation.|
|`operations_rejectExpired`|Operation has expired when trying to reject the operation.|
|`operations_QROperationFailed`|Couldn't sign QR operation.|

### Push errors

| Option Name | Description |
|---|---|
|`push_alreadyRegistering`|Push registration is already in progress.|
