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

/// Utility class used for handling TOTP
public class WMTTOTPUtils {
    
    /// Method accepts deeeplink URL and returns payload data
    public static func parseLoginDeeplink(url: URL) -> WMTOperationTOTPData? {
        
        guard let components = URLComponents(string: url.absoluteString) else { return nil }
        
        guard let host = components.host, host == "login" else { return nil }
        
        guard let queryItems = components.queryItems else { return nil }
        
        guard let code = queryItems.first?.value else { return nil }
        
        guard let data = parseJWT(code: code) else { return nil }
        
        return data
    }
    
    /// Method accepts scanned code as a String and returns payload data
    public static func getTOTPFromQR(code: String) -> WMTOperationTOTPData? {
        return parseJWT(code: code)
    }
    
    private static func parseJWT(code: String) -> WMTOperationTOTPData? {
        let jwtParts = code.split(separator: ".")
        
        // At this moment we dont care about header, we want only payload which is the second part of JWT
        let jwtBase64String = jwtParts.count > 1 ? String(jwtParts[1]) : ""
        
        if let base64EncodedData = jwtBase64String.data(using: .utf8),
           let dataPayload = Data(base64Encoded: base64EncodedData) {
            
            do {
                return try JSONDecoder().decode(WMTOperationTOTPData.self, from: dataPayload)
            } catch {
                D.error("Failed to decode QR JWT: \(code)")
                D.error("With error: \(error)")
                return nil
            }
        }
        
        D.error("Failed to decode QR JWT from: \(jwtBase64String)")
        return nil
    }
}

/// Data payload which is
public struct WMTOperationTOTPData: Codable {
    
    /// The actual Time-based one time password
    public let totp: String
    
    /// Id of the operations to which the otp belongs to
    public let operationId: String
    
    public enum Keys: String, CodingKey {
        case totp = "totp"
        case operationId = "oid"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        totp = try container.decode(String.self, forKey: .totp)
        operationId = try container.decode(String.self, forKey: .operationId)
    }
}
