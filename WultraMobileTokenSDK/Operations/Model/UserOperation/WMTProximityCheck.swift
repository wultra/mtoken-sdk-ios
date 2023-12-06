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

/// Object which is used to hold data about proximity check
///
/// Data shall be assigned to the operation when obtained
public class WMTProximityCheck: Codable {
    
    /// Tha actual Time-based one time password
    public let totp: String
    
    /// Type of the Proximity check
    public let type: WMTProximityCheckType
    
    /// Timestamp when the operation was scanned (qrCode) or delivered to the device (deeplink)
    public let timestampReceived: Date
    
    public init(totp: String, type: WMTProximityCheckType, timestampReceived: Date = Date()) {
        self.totp = totp
        self.type = type
        self.timestampReceived = timestampReceived
    }
}

/// Types of possible Proximity Checks
public enum WMTProximityCheckType: String, Codable {
    case qrCode = "QR_CODE"
    case deeplink = "DEEPLINK"
}
