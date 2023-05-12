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

public class WMTPostApprovalScreenReview: WMTPostApprovalScreen {
    
    /// Heading of the post-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Payload with data about action after the operation
    public let payload: ReviewPostApprovalScreenPayload
    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case heading, message, payload
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        payload = try c.decode(ReviewPostApprovalScreenPayload.self, forKey: .payload)
        try super.init(from: decoder)
    }
}

/// Payload of the review post-approval screen shows the operation attributes.
public class ReviewPostApprovalScreenPayload: PostApprovalScreenPayload {
    
    /// Review attributes contains info
    public let attributes: [ReviewAttributes]
    
    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case attributes, type, id, label, note
    }
    
    public class ReviewAttributes: Codable {
        
        public let type: String
        
        public let id: String
        
        public let label: String
        
        public let note: String
        
        private enum AttributesKeys: String, CodingKey {
            case type, id, label, note
        }
        
        public init(type: String, id: String, label: String, note: String) {
            self.type = type
            self.id = id
            self.label = label
            self.note = note
        }
        
        public required init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: AttributesKeys.self)
            type = try c.decode(String.self, forKey: .type)
            id = try c.decode(String.self, forKey: .id)
            label = try c.decode(String.self, forKey: .label)
            note = try c.decode(String.self, forKey: .note)
        }
    }
    
    public init(attributes: [ReviewAttributes]) {
        self.attributes = attributes
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        attributes = try c.decode([ReviewAttributes].self, forKey: .attributes)
        super.init()
    }
}
