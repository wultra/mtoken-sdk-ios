//
// Copyright 2023 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import Foundation
import PowerAuth2

/// Object which is used to hold data about proximity check.
///
/// Assign this object to the operation's `proximityCheck` property before calling `authorize`.
/// The SDK automatically synchronizes timestamps with the server during authorization,
/// so you only need to provide the `totp` and `type`.
public class WMTProximityCheck: Codable {
    
    /// The actual Time-based one-time password.
    public let totp: String
    
    /// Type of the Proximity check.
    public let type: WMTProximityCheckType
    
    /// Timestamp when the operation was scanned (QR code) or delivered to the device (Deeplink).
    ///
    /// Captured automatically as the current system time at creation.
    public let timestampReceived: Date
    
    /// Creates a new proximity check.
    ///
    /// - Parameters:
    ///   - totp: The Time-based one-time password.
    ///   - type: The proximity check type (`.qrCode` or `.deeplink`).
    public init(totp: String, type: WMTProximityCheckType) {
        self.totp = totp
        self.type = type
        self.timestampReceived = Date()
    }
    
    /// Creates a new proximity check.
    ///
    /// The `timestampReceived` parameter is ignored — the SDK captures `Date()` at creation
    /// and adjusts it to server time internally during `authorize`.
    ///
    /// - Parameters:
    ///   - totp: The Time-based one-time password.
    ///   - type: The proximity check type.
    ///   - timestampReceived: Ignored. The SDK uses `Date()` and adjusts it during operation authorization.
    @available(*, deprecated, message: "Use init(totp:type:) instead. The SDK now handles time synchronization internally during authorize.")
    public convenience init(totp: String, type: WMTProximityCheckType, timestampReceived: Date) {
        self.init(totp: totp, type: type)
    }

    /// Deprecated. Previously synchronized `timestampReceived` with the PowerAuth server.
    ///
    /// This is no longer needed — the SDK now handles time synchronization internally
    /// during `authorize(operation:with:)`. This method simply creates a `WMTProximityCheck`
    /// with `Date()` as the timestamp; the `powerAuthSDK` parameter is ignored.
    ///
    /// - Parameters:
    ///   - totp: The TOTP code.
    ///   - type: The proximity check type.
    ///   - powerAuthSDK: Instance of `PowerAuthSDK` (no longer used).
    @available(*, deprecated, message: "Use init(totp:type:) instead. The SDK now handles time synchronization internally during authorize.")
    public static func withSynchronizedTime(
        totp: String,
        type: WMTProximityCheckType,
        powerAuthSDK: PowerAuthSDK
    ) -> WMTProximityCheck {
        return WMTProximityCheck(totp: totp, type: type)
    }
}

/// Types of possible Proximity Checks
public enum WMTProximityCheckType: String, Codable {
    case qrCode = "QR_CODE"
    case deeplink = "DEEPLINK"
}
