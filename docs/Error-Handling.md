# Error Handling

Errors produced by this library are of type `WPNError` that comes from our networking layer. For more information visit [the library documentation](https://github.com/wultra/networking-apple).


## Custom Error Reasons

In addition to pre-defined error reasons available in the networking library, we offer more reasons to further offer better error handling.

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
