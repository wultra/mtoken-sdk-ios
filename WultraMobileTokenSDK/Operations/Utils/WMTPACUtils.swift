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

/// Utility class used for handling Proximity Antifraud Check
public class WMTPACUtils {
    
    /// Method accepts deeplink URL and returns PAC data
    public static func parseDeeplink(url: URL) -> WMTPACData? {
        
        guard let components = URLComponents(string: url.absoluteString) else {
            D.error("Failed to get URLComponents: URLString is malformed \(url)")
            return nil
        }
        
        guard let queryItems = components.queryItems else {
            D.error("Failed to get URLComponents queryItems for \(url)")
            return nil
        }
        
        // Deeplink can have two query items with operationId & optional totp or single query item with JWT value
        if let operationId = queryItems.first(where: { $0.name == "oid" })?.value?.removingPercentEncoding {
            let totp = queryItems.first(where: { $0.name == "totp" || $0.name == "potp" })?.value?.removingPercentEncoding
            return WMTPACData(operationId: operationId, totp: totp)
        } else if let code = queryItems.first?.value {
            return parseJWT(code: code)
        } else {
            D.error("Failed to get Query Items values for parsing")
            return nil
        }
    }
    
    /// Method accepts scanned code as a String and returns PAC data - it can be in deeplink format or JWT
    public static func parseQRCode(code: String) -> WMTPACData? {
        guard let encodedURLString = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedURLString) else {
            return parseJWT(code: code)
        }
        // if the QR code is in the deeplink format parse it the same way as the deeplink
        if url.scheme != nil {
            return parseDeeplink(url: url)
        } else {
            return parseJWT(code: code)
        }
    }
    
    private static func parseJWT(code: String) -> WMTPACData? {
        let jwtParts = code.split(separator: ".")

        // At this moment we dont care about header, we want only payload which is the second part of JWT
        let jwtBase64String = jwtParts.count > 1 ? String(jwtParts[1]) : ""

        if let dataPayload = Data(base64Encoded: jwtBase64String.addBase64Padding) {
            do {
                return try JSONDecoder().decode(WMTPACData.self, from: dataPayload)
            } catch {
                D.error("Failed to decode JWT from: \(code)")
                D.error("With error: \(error)")
                return nil
            }
        }

        D.error("Failed to decode QR JWT from: \(jwtBase64String)")
        return nil
    }
}

/// Data which is returned from parsing PAC code
public struct WMTPACData: Decodable {
    
    /// The ID of the operation associated with the PAC
    public let operationId: String
    
    /// Time-based one time password used for Proximity antifraud check
    public let totp: String?
    
    enum Keys: String, CodingKey {
        case totp = "totp"
        case potp = "potp" // to keep backward compatibility
        case operationId = "oid"
    }
    
    public init(operationId: String, totp: String?) {
        self.operationId = operationId
        self.totp = totp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        operationId = try container.decode(String.self, forKey: .operationId)
        if let t = try container.decodeIfPresent(String.self, forKey: .totp) {
            totp = t
        } else if let p = try container.decodeIfPresent(String.self, forKey: .potp) {
            totp = p
        } else {
            totp = nil
        }
    }
}

private extension String {
    var addBase64Padding: String {
        let offset = count % 4
        if offset > 0 {
            return padding(toLength: count + 4 - offset, withPad: "=", startingAt: 0)
        }
        return self
    }
}
