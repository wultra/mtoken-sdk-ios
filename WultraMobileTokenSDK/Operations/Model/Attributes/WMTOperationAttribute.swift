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

public enum WMTOperationAttributeType: String, Codable {
    case amount     = "AMOUNT"      // amount, like "100.00 CZK"
    case keyValue   = "KEY_VALUE"   // any key value pair
    case note       = "NOTE"        // just like KEY_VALUE, emphasising that the value is a note, or message
    case heading    = "HEADING"     // single highlighted text, written in a larger font, used as a section heading
    case partyInfo  = "PARTY_INFO"  // for displaying third party information
}

public enum WMTOperationAttributeError: Error {
    case unknownType
}

public class WMTOperationAttribute: Codable {
    
    public let type: WMTOperationAttributeType
    public let label: WMTOperationParameter
    
    private enum Keys: String, CodingKey {
        case id = "id"
        case value = "label"
        case operationType = "type"
    }
    
    public init(type: WMTOperationAttributeType, label: WMTOperationParameter) {
        self.type = type
        self.label = label
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        let id = try c.decode(String.self, forKey: .id)
        let value = try c.decode(String.self, forKey: .value)
        let t = try c.decode(String.self, forKey: .operationType)
        
        guard let opType = WMTOperationAttributeType(rawValue: t) else {
            throw WMTOperationAttributeError.unknownType
        }
        
        label = WMTOperationParameter(id: id, value: value)
        type = opType
    }
    
    /// This is convenience function to implement Polymorphic behavior on array with different types of attributes
    class func decode(decoder: Decoder) throws -> WMTOperationAttribute {
        
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .operationType)
        guard let opType = WMTOperationAttributeType(rawValue: t) else {
            throw WMTOperationAttributeError.unknownType
        }
        
        switch opType {
        case .amount: return try WMTOperationAttributeAmount(from: decoder)
        case .keyValue: return try WMTOperationAttributeKeyValue(from: decoder)
        case .note: return try WMTOperationAttributeNote(from: decoder)
        case .heading: return try WMTOperationAttributeHeading(from: decoder)
        case .partyInfo: return try WMTOperationAttributePartyInfo(from: decoder)
        }
    }
}
