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

public class WMTPostApprovalScreenGeneric: WMTPostApprovalScreen {
    
    /// Heading of the post-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Payload with data about action after the operation
    public let payload: WMTJSONValue

    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case heading, message, payload
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        payload = try c.decode(WMTJSONValue.self, forKey: .payload)
        try super.init(from: decoder)
    }
    
    public init(heading: String, message: String, payload: WMTJSONValue) {
        self.heading = heading
        self.message = message
        self.payload = payload
        super.init(type: .generic)
    }
}
