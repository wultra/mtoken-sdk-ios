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

/// WMTPreApprovalScreen contains data to be presented before approving operation
///
/// `type` define different kind of data which can be passed with operation
/// and shall be displayed before operation is confirmed
public class WMTPreApprovalScreen: Codable {
    
    /// Type of PreApprovalScreen (`WARNING`, `INFO`, `QR_SCAN` or unknown for future compatibility )
    public let type: ScreenType
    
    /// Heading of the pre-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Array of items to be displayed as list of choices
    public let items: [String]?
    
    /// Type of the approval button
    public let approvalType: WMTPreApprovalScreenConfirmAction?
    
    // MARK: - INTERNALS
    
    public enum ScreenType: String, Codable {
        case info = "INFO"
        case warning = "WARNING"
        case qr = "QR_SCAN"
        case unknown = "UNKNOWN"
    }
    
    private enum Keys: String, CodingKey {
        case type, heading, message, items, approvalType
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .type)
        type = ScreenType(rawValue: t) ?? .unknown
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        items = try? c.decode([String].self, forKey: .items)
        approvalType = try? c.decode(WMTPreApprovalScreenConfirmAction.self, forKey: .approvalType)
    }
    
    public init(type: ScreenType, heading: String, message: String, items: [String]? = nil, approvalType: WMTPreApprovalScreenConfirmAction?) {
        self.type = type
        self.heading = heading
        self.message = message
        self.items = items
        self.approvalType = approvalType
    }
}

/// Type of action which is used within Derived PreApproval classes to define
/// how the confirm action shall be performed
public enum WMTPreApprovalScreenConfirmAction: String, Codable {
    case slider = "SLIDER"
}
