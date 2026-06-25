# Migration from 2.4.x to 2.5.x

This guide provides instructions for migrating from **Wultra Mobile Token SDK for iOS** version `2.4.x` to version `2.5.x`.

Version `2.5.x` improves proximity check time handling. There are **no breaking changes** — only deprecations.

---

### Proximity Check Time Synchronization (Improved)

The SDK now automatically synchronizes timestamps with the PowerAuth server when authorizing an operation with a proximity check. This eliminates issues that could occur when the device's system time is incorrect (e.g., manually changed by the user) and the proximity check is created before time synchronization completes.

**Before (2.4.x):**

You were responsible for providing a server-synchronized timestamp, typically using `withSynchronizedTime`:

```swift
let proximityCheck = WMTProximityCheck.withSynchronizedTime(
    totp: totp,
    type: .qrCode,
    powerAuthSDK: powerAuth
)
operation.proximityCheck = proximityCheck
```

**After (2.5.x):**

Simply create the proximity check with the TOTP and type. The SDK handles time synchronization internally during `authorize`:

```swift
operation.proximityCheck = WMTProximityCheck(totp: totp, type: .qrCode)
```

---

### Deprecated APIs

| Deprecated | Replacement |
|---|---|
| `WMTProximityCheck.withSynchronizedTime(totp:type:powerAuthSDK:)` | `WMTProximityCheck(totp:type:)` |
| `WMTProximityCheck.init(totp:type:timestampReceived:)` | `WMTProximityCheck(totp:type:)` |

The deprecated APIs continue to work but their behavior has changed. The `timestampReceived` parameter in `init(totp:type:timestampReceived:)` is now **ignored** — the SDK always captures `Date()` and adjusts it to server time during `authorize`. Custom timestamps are not supported because the SDK can only correct the system clock offset, not arbitrary values provided by the consumer.

---
