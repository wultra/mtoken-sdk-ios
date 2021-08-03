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

/// Operation data, that should be visible to the user.
///
/// Note that the data returned from the server are localized based on the `WMTOperations.acceptLanguage` property.
public class WMTOperationFormData: Codable {
    
    /// Title of the operation
    public let title: String
    
    /// Message for the user
    public let message: String
    
    /// Other attributes.
    ///
    /// Note that attributes can be presented with different classes (Starting with `WMTOperationAttribute*`) based on the attribute type.
    public let attributes: [WMTOperationAttribute]
    
    // MARK: - INTERNALS
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        title = try c.decode(String.self, forKey: .title)
        message = try c.decode(String.self, forKey: .message)
        // attributes are optional
        attributes = (try? c.decode([WMTOperationAttributeDecodable].self, forKey: .attributes).map { $0.attrObject }) ?? []
    }
    
    public init(title: String, message: String, attributes: [WMTOperationAttribute]) {
        self.title = title
        self.message = message
        self.attributes = attributes
    }
    
    private enum Keys: CodingKey {
        case title, message, attributes
    }
}

// This class acts as "translation layer" for decoding polymorphic property of "attributes"
// property inside OperationFormData class that can have multiple types of Attribute inside
private class WMTOperationAttributeDecodable: Decodable {
    
    fileprivate let attrObject: WMTOperationAttribute
    
    required init(from decoder: Decoder) throws {
        attrObject = try WMTOperationAttribute.decode(decoder: decoder)
    }
}
