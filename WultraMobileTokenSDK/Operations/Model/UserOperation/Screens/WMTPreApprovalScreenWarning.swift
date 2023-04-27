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

public class WMTPreApprovalScreenWarning: WMTPreApprovalScreen {
    
    /// Heading of the pre-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Array of items to be displayed as list of choices
    public let items: [String]
    
    /// Type of the approval button
    public let approvalType: PreApprovalScreenConfirmAction
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case heading, message, items, approvalType
    }
    
    public init(heading: String, message: String, items: [String], approvalType: PreApprovalScreenConfirmAction, type: PreApprovalScreenType) {
        self.heading = heading
        self.message = message
        self.items = items
        self.approvalType = approvalType
        super.init(type: type)
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        items = try c.decode([String].self, forKey: .items)
        approvalType = try c.decode(PreApprovalScreenConfirmAction.self, forKey: .approvalType)
        try super.init(from: decoder)
    }
}
