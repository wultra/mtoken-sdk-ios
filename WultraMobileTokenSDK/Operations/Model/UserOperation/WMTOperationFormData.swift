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
    
    /// Texts for the result of the operation
    ///
    /// This includes messages for different outcomes of the operation such as success, rejection, and failure.
    public let resultTexts: WMTResultTexts?
    
    /// Other attributes.
    ///
    /// Note that attributes can be presented with different classes (Starting with `WMTOperationAttribute*`) based on the attribute type.
    public let attributes: [WMTOperationAttribute]
    
    // MARK: - INTERNALS
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        title = try c.decode(String.self, forKey: .title)
        message = try c.decode(String.self, forKey: .message)
        
        if c.contains(.resultTexts) {
            do {
                resultTexts = try c.decode(WMTResultTexts.self, forKey: .resultTexts)
            } catch {
                D.error("Failed to decode \(Keys.resultTexts) - \(error), setting to null")
                resultTexts = nil
            }
        } else {
            resultTexts = nil
        }
        
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
    }
    
    public init(title: String, message: String, attributes: [WMTOperationAttribute], resultTexts: WMTResultTexts? = nil) {
        self.title = title
        self.message = message
        self.attributes = attributes
        self.resultTexts = resultTexts
    }
    
    private enum Keys: CodingKey {
        case title, message, attributes, resultTexts
    }
}

// This class acts as "translation layer" for decoding polymorphic property of "attributes"
// property inside OperationFormData class that can have multiple types of Attribute inside
class WMTOperationAttributeDecodable: Decodable {
    
    let attrObject: WMTOperationAttribute
    
    required init(from decoder: Decoder) throws {
        attrObject = try WMTOperationAttribute.decode(decoder: decoder)
    }
}
