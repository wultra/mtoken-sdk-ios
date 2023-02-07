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

/// Operation Attribute can be visualized as "1 row in operation screen"
///
/// `WMTOperationAttribute` is considered to be "abstract".
/// Every type of the attribute has it's own strongly typed implementation
public class WMTOperationAttribute: Codable {
    
    /// Type of the operation.
    public let type: AttributeType
    
    /// Label for the value.
    public let label: AttributeLabel
    
    // MARK: - INNER CLASSES
    
    /// Attribute type. Based on this type, proper class will be chosen for "deserialization".
    public enum AttributeType: String, Codable {
        case amount           = "AMOUNT"            // amount, like "100.00 CZK"
        case amountConversion = "AMOUNT_CONVERSION" // Currency conversion, for example when changing money from USD to EUR
        case keyValue         = "KEY_VALUE"         // any key value pair
        case note             = "NOTE"              // just like KEY_VALUE, emphasizing that the value is a note or message
        case heading          = "HEADING"           // single highlighted text, written in a larger font, used as a section heading
        case partyInfo        = "PARTY_INFO"        // for displaying third party information
        case unknown          = "UNKNOWN"           // when unknown attribute is presented, it will be returned as unknown
    }
    
    /// Attribute label serves as a UI heading for the attribute.
    public class AttributeLabel: Codable {
        
        /// ID (type) of the label. This is highly depended on the backend
        /// and can be used to change the appearance of the label
        public let id: String
        
        /// Label value
        public let value: String
        
        public init(id: String, value: String) {
            self.id = id
            self.value = value
        }
    }
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case id = "id"
        case value = "label"
        case operationType = "type"
    }
    
    public init(type: AttributeType, label: AttributeLabel) {
        self.type = type
        self.label = label
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        let id = try c.decode(String.self, forKey: .id)
        let value = try c.decode(String.self, forKey: .value)
        let t = try c.decode(String.self, forKey: .operationType)
        
        label = AttributeLabel(id: id, value: value)
        type = AttributeType(rawValue: t) ?? .unknown
    }
    
    /// This is convenience function to implement Polymorphic behavior on array with different types of attributes
    class func decode(decoder: Decoder) throws -> WMTOperationAttribute {
        
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .operationType)
        let opType = AttributeType(rawValue: t) ?? .unknown
        
        switch opType {
        case .amount: return try WMTOperationAttributeAmount(from: decoder)
        case .keyValue: return try WMTOperationAttributeKeyValue(from: decoder)
        case .note: return try WMTOperationAttributeNote(from: decoder)
        case .heading: return try WMTOperationAttributeHeading(from: decoder)
        case .partyInfo: return try WMTOperationAttributePartyInfo(from: decoder)
        case .amountConversion: return try WMTOperationAttributeAmountConversion(from: decoder)
        case .unknown: return try WMTOperationAttribute(from: decoder)
        }
    }
}
