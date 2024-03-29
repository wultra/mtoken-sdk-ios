//
// Copyright 2020 Wultra s.r.o.
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

/// Data for operation approval request.
class WMTAuthorizationData: Codable {
    
    /// Signed data
    let data: String
    
    /// Operation id
    let id: String
    
    /// Proximity OTP data
    let proximityCheck: WMTProximityCheckData?
    
    init(operationId: String, operationData: String, proximityCheck: WMTProximityCheckData? = nil) {
        self.id = operationId
        self.data = operationData
        self.proximityCheck = proximityCheck
    }
    
    init(operation: WMTOperation, timestampSent: Date = Date()) {
        self.id = operation.id
        self.data = operation.data
        
        guard let proximityCheck = operation.proximityCheck else {
            self.proximityCheck = nil
            return
        }
        
        self.proximityCheck = WMTProximityCheckData(
            otp: proximityCheck.totp,
            type: proximityCheck.type,
            timestampReceived: proximityCheck.timestampReceived,
            timestampSent: timestampSent
        )
    }
}

/// Internal proximity check data used for authorization
struct WMTProximityCheckData: Codable {
    
    /// Tha actual OTP code
    let otp: String
    
    /// Type of the Proximity check
    let type: WMTProximityCheckType
    
    /// Timestamp when the operation was delivered to the app
    let timestampReceived: Date
    
    /// Timestamp when the operation was signed
    let timestampSent: Date
}
