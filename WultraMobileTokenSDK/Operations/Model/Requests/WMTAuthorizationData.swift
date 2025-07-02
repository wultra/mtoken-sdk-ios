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
internal class WMTAuthorizationData: Codable {
    
    /// Signed data
    let data: String
    
    /// Operation id
    let id: String
    
    /// Proximity OTP data
    let proximityCheck: WMTProximityCheckData?
    
    /// Optional mobile token data, structure is customer-specific.
    /// Could be used, for example, for passing FDS data.
    /// Available with PowerAuth server 1.10+.
    let mobileTokenData: [String: AnyEncodable]?
    
    init(operationId: String, operationData: String, proximityCheck: WMTProximityCheckData? = nil, mobileTokenData: [String: Encodable]? = nil) {
        self.id = operationId
        self.data = operationData
        self.mobileTokenData = mobileTokenData?.toAnyEncodable()
        self.proximityCheck = proximityCheck
    }
    
    init(operation: WMTOperation, timestampSent: Date = Date()) {
        self.id = operation.id
        self.data = operation.data
        self.mobileTokenData = operation.mobileTokenData?.toAnyEncodable()
        
        if let proximityCheck = operation.proximityCheck {
            self.proximityCheck = WMTProximityCheckData(
                otp: proximityCheck.totp,
                type: proximityCheck.type,
                timestampReceived: proximityCheck.timestampReceived,
                timestampSent: timestampSent
            )
        } else {
            self.proximityCheck = nil
        }
    }
    
    required init(from decoder: any Decoder) throws {
        // Decoding is not supported for this class, as it is used for signing data.
        throw DecoderError.decodingNotSupported
    }
}

/// Internal proximity check data used for authorization
internal struct WMTProximityCheckData: Codable {
    
    /// Tha actual OTP code
    let otp: String
    
    /// Type of the Proximity check
    let type: WMTProximityCheckType
    
    /// Timestamp when the operation was delivered to the app
    let timestampReceived: Date
    
    /// Timestamp when the operation was signed
    let timestampSent: Date
}

internal struct AnyEncodable: Encodable {
    
    internal let original: Encodable

    init<T: Encodable>(_ wrapped: T) {
        original = wrapped
    }

    func encode(to encoder: Encoder) throws {
        try original.encode(to: encoder)
    }
}

private extension Dictionary where Key == String, Value == Encodable {
    func toAnyEncodable() -> [String: AnyEncodable] {
        return mapValues { AnyEncodable($0) }
    }
}

private enum DecoderError: Error {
    case decodingNotSupported
}
