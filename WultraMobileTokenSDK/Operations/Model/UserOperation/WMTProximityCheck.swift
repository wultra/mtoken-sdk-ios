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
/// Data shall be assigned to the operation when accessed
public class WMTProximityCheck: Codable {
    
    /// Tha actual otp code
    public let otp: String
    
    /// Type of the Proximity check
    public let type: WMTProximityCheckType
    
    /// Timestamp when the operation was delivered to the device
    public let timestampRequested: Date
    
    public init(otp: String, type: WMTProximityCheckType, timestampRequested: Date = Date()) {
        self.otp = otp
        self.type = type
        self.timestampRequested = timestampRequested
    }
}

/// Types of possible Proximity Checks
public enum WMTProximityCheckType: String, Codable {
    case qrCode = "QR_CODE"
    case deeplink = "DEEPLINK"
}
