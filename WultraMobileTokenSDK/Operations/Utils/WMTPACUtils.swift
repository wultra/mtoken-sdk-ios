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
            D.error("Failed to get URLComponents: URLString is malformed")
            return nil
        }
        
        guard let queryItems = components.queryItems else {
            D.error("Failed to get URLComponents queryItems")
            return nil
        }
        
        if let operationId = queryItems.first(where: { $0.name == "oid" })?.value {
            let totp = queryItems.first(where: { $0.name == "totp" })?.value
            return WMTPACData(operationId: operationId, totp: totp)
        } else {
            D.error("Failed to get operationId from query items")
            return nil
        }
    }
    
    /// Method accepts scanned code as a String and returns PAC data
    public static func parseQRCode(code: String) -> WMTPACData? {
        if let encodedURLString = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedURLString) {
            return parseDeeplink(url: url)
        } else {
            D.error("Failed to created URL from QR code String.")
            return nil
        }
    }
}

/// Data which is return after parsing PAC code
public struct WMTPACData {
    
    /// The ID of the operation associated with the PAC
    public let operationId: String
    
    /// Time-based one time password used for Proximity antifraud check
    public let totp: String?
}
