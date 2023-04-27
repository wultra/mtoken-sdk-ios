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

/// WMTPreApprovalScreen is the base class for Pre Approval screen classes
///
/// `type` define different kind of data which can be passed with operation
/// and shall be displayed before operation is confirmed
public class WMTPreApprovalScreen: Codable {
    
    /// type of PreApprovalScrren is presented with different classes (Starting with `WMTPreApprovalScreen*`)
    public let type: PreApprovalScreenType
    
    public enum PreApprovalScreenType: String, Codable {
        case info = "INFO"
        case warning = "WARNING"
        case qr = "QR"
    }
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case type
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        type = try c.decode(PreApprovalScreenType.self, forKey: .type)
    }
    
    public init(type: PreApprovalScreenType) {
        self.type = type
    }
    
    /// This is convenience function to implement Polymorphic behavior with different types of screens
    class func decode(decoder: Decoder) throws -> WMTPreApprovalScreen? {
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .type)
        let preType = PreApprovalScreenType(rawValue: t)
        
        switch preType {
        case .info: return try WMTPreApprovalScreenInfo(from: decoder)
        case .warning: return try WMTPreApprovalScreenWarning(from: decoder)
        default:
            D.error("Unknown preApproval type: \(t)")
            return nil
        }
    }
}

/// Type of action which is used within Derived PreApproval classes to define
/// how the confirm action shall be performed
public enum PreApprovalScreenConfirmAction: String, Codable {
    case slider = "SLIDER"
}
