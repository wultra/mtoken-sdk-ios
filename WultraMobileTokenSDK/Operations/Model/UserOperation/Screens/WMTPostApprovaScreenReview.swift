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

/// Review screen shows the operation attributes
public class WMTPostApprovalScreenReview: WMTPostApprovalScreen {
    
    /// Heading of the post-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Payload with data about action after the operation
    public let payload: WMTReviewPostApprovalScreenPayload
    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case heading, message, payload
    }
    
    public init(heading: String, message: String, payload: WMTReviewPostApprovalScreenPayload, type: ScreenType) {
        self.heading = heading
        self.message = message
        self.payload = payload
        super.init(type: type)
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        payload = try c.decode(WMTReviewPostApprovalScreenPayload.self, forKey: .payload)
        try super.init(from: decoder)
    }
}

/// Payload of the review post-approval screen shows the operation attributes.
public class WMTReviewPostApprovalScreenPayload: WMTPostApprovalScreenPayload {
    
    /// Attributes as in FormData but its data might be only a subset
    public let attributes: [WMTOperationAttribute]
    
    // MARK: Internals
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        
        var operationAttributes: [WMTOperationAttribute] = []
        do {
            var container = try c.nestedUnkeyedContainer(forKey: .attributes)
            // If decoding fails log it and continue decoding until the end of container
            while container.isAtEnd == false {
                do {
                    let attribute = try WMTOperationAttributeDecodable(from: container.superDecoder())
                    operationAttributes.append(attribute.attrObject)
                } catch {
                    D.error("Error decoding WMTOperationFormData attribute: \(error)")
                }
            }
        } catch {
            D.error("No attributes in WMTOperationFormData: \(error)")
        }
        attributes = operationAttributes
        
        super.init()
    }
    
    public init(attributes: [WMTOperationAttribute]) {
        self.attributes = attributes
        super.init()
    }
    
    private enum Keys: CodingKey {
        case attributes
    }
}
